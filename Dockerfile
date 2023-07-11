
# Build WAL-G
# https://github.com/wal-g/wal-g/pull/1315#issuecomment-1208982468
FROM golang:alpine3.18 AS builder
ENV WALG_VERSION=v2.0.1
ENV _build_deps="wget cmake git build-base bash"
RUN set -ex  \
     && apk add --no-cache $_build_deps \
     && git clone https://github.com/wal-g/wal-g/  $GOPATH/src/wal-g \
     && cd $GOPATH/src/wal-g/ \
     && git checkout $WALG_VERSION \
     && make install_and_build_pg \
     && install main/pg/wal-g / \
     && /wal-g --help

# Use a imagem base do TimescaleDB com PostgreSQL 15
FROM timescale/timescaledb:latest-pg15

# Instale o PostGIS
# https://github.com/badtuxx/prometheus_alpine/blob/master/Dockerfile
ENV POSTGIS_VERSION 3.3.3

RUN set -eux \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        \
        gdal-dev \
        geos-dev \
        proj-dev \
        proj-util \
        sfcgal-dev \
        \
        # The upstream variable, '$DOCKER_PG_LLVM_DEPS' contains
        #  the correct versions of 'llvm-dev' and 'clang' for the current version of PostgreSQL.
        # This improvement has been discussed in https://github.com/docker-library/postgres/pull/1077
        $DOCKER_PG_LLVM_DEPS \
        \
        autoconf \
        automake \
        cunit-dev \
        file \
        g++ \
        gcc \
        gettext-dev \
        git \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        pcre2-dev \
        perl \
        protobuf-c-dev \
    \
# build PostGIS - with Link Time Optimization (LTO) enabled
    && cd /usr/src/postgis \
    && gettextize \
    && ./autogen.sh \
    && ./configure \
        --enable-lto \
    && make -j$(nproc) \
    && make install \
    \
# This section is for refreshing the proj data for the regression tests.
# It serves as a workaround for an issue documented at https://trac.osgeo.org/postgis/ticket/5316
# This increases the Docker image size by about 1 MB.
    && projsync --system-directory --file ch_swisstopo_CHENyx06_ETRS \
    && projsync --system-directory --file us_noaa_eshpgn \
    && projsync --system-directory --file us_noaa_prvi \
    && projsync --system-directory --file us_noaa_wmhpgn \
# This section performs a regression check.
    && mkdir /tempdb \
    && chown -R postgres:postgres /tempdb \
    && su postgres -c 'pg_ctl -D /tempdb init' \
    && su postgres -c 'pg_ctl -D /tempdb start' \
    && cd regress \
    && make -j$(nproc) check RUNTESTFLAGS=--extension   PGUSER=postgres \
    \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch; --needed for postgis_tiger_geocoder "' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer_data_us;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"' \
    && su postgres -c 'psql -t -c "SELECT version();"'              >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "SELECT PostGIS_Full_Version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "\dx"' >> /_pgis_full_version.txt \
    \
    && su postgres -c 'pg_ctl -D /tempdb --mode=immediate stop' \
    && rm -rf /tempdb \
    && rm -rf /tmp/pgis_reg \
# add .postgis-rundeps
    && apk add --no-cache --virtual .postgis-rundeps \
        \
        gdal \
        geos \
        proj \
        sfcgal \
        \
        json-c \
        libstdc++ \
        pcre2 \
        protobuf-c \
        \
        # ca-certificates: for accessing remote raster files
        #   fix https://github.com/postgis/docker-postgis/issues/307
        ca-certificates \
# clean
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps \
# At the end of the build, we print the collected information
# from the '/_pgis_full_version.txt' file. This is for experimental and internal purposes.
    && cat /_pgis_full_version.txt

# Instale as dependências necessárias
RUN apk add --no-cache wget tar curl

# Instalando o Prometheus e postgres_exporter
RUN apk add --no-cache prometheus && \
    chown postgres:postgres /var/lib/prometheus &&\
    wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.13.1/postgres_exporter-0.13.1.linux-amd64.tar.gz && \
    tar -zxvf postgres_exporter-0.13.1.linux-amd64.tar.gz && \
    mv postgres_exporter-0.13.1.linux-amd64/postgres_exporter /usr/local/bin/ && \
    rm -rf postgres_exporter-0.13.1.linux-amd64.tar.gz

# Instale o WAL-G
COPY --from=builder /wal-g /usr/local/bin/

# Copie o arquivo de configuração do Prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Copie o arquivo de configuração do PostgreSQL Server Exporter
#COPY postgres_exporter.yml /etc/prometheus/prometheus.yml

# Copie o script de backup diário para o diretório /docker-entrypoint-initdb.d/
#COPY backup.sh /docker-entrypoint-initdb.d/backup.sh
COPY backup.sh /usr/local/bin/backup-pg.sh
COPY archive.sh /usr/local/bin/archive-pg.sh

# Copie o script de teste para o diretório /usr/local/bin/
COPY test.sh /usr/local/bin/test.sh

# Configure a extensão PostGIS
#COPY postgis.sql /docker-entrypoint-initdb.d/postgis.sql
COPY postgis.sh /docker-entrypoint-initdb.d/postgis.sh

# Inicializacao dos servicos
COPY init-services.sh /usr/local/bin/init-services.sh

# Dê permissão de execução ao script de backup e ao script de teste
RUN chmod +x /usr/local/bin/*.sh /docker-entrypoint-initdb.d/postgis.sh

# Variáveis de ambiente padrão para configuração do servidor AWS
ENV AWS_ENDPOINT="s3.amazonaws.com"
ENV AWS_S3_BUCKET="your-bucket-name"
ENV AWS_ACCESS_KEY_ID="your-access-key"
ENV AWS_SECRET_ACCESS_KEY="your-secret-key"

# Variável de ambiente para o número de dias de retenção do backup
ENV BACKUP_RETENTION_DAYS=7

# Variável de ambiente para o diretório de backup
ENV BACKUP_DIRECTORY="/backups"

# Exponha as portas necessárias
EXPOSE 5432 9090 9187

# Inicie o PostgreSQL Server Exporter e o teste em segundo plano
#CMD ["postgres","-c","wal_buffers=64MB"]
RUN sed -i '/exec "$@"/i archive-pg.sh' /usr/local/bin/docker-entrypoint.sh
RUN sed -i '/exec "$@"/i init-services.sh &' /usr/local/bin/docker-entrypoint.sh
