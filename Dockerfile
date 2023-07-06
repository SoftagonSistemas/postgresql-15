# Use a imagem base do TimescaleDB com PostgreSQL 15
FROM timescale/timescaledb:latest-pg15

# Instale as dependências necessárias
RUN apk add --no-cache wget tar

# Instale o Prometheus
RUN wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.13.1/postgres_exporter-0.13.1.linux-amd64.tar.gz && \
    tar -zxvf postgres_exporter-0.13.1.linux-amd64.tar.gz && \
    mv postgres_exporter-0.13.1.linux-amd64/postgres_exporter /usr/local/bin/ && \
    rm -rf postgres_exporter-0.13.1.linux-amd64.tar.gz

# Instale o PostGIS
RUN apk add --no-cache postgis

# Instale o WAL-G
RUN wget https://github.com/wal-g/wal-g/releases/download/v2.0.1/wal-g-fdb-ubuntu-18.04-amd64.tar.gz && \
    tar -zxvf wal-g-fdb-ubuntu-18.04-amd64.tar.gz && \
    mv wal-g-fdb-ubuntu-18.04-amd64 /usr/local/bin/wal-g && \
    rm wal-g-fdb-ubuntu-18.04-amd64.tar.gz

# Copie o arquivo de configuração do Prometheus
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Copie o arquivo de configuração do PostgreSQL Server Exporter
COPY postgres_exporter.yml /etc/prometheus/postgres_exporter.yml

# Copie o script de backup diário para o diretório /docker-entrypoint-initdb.d/
COPY backup.sh /docker-entrypoint-initdb.d/backup.sh

# Copie o script de teste para o diretório /usr/local/bin/
COPY test.sh /usr/local/bin/test.sh

# Dê permissão de execução ao script de backup e ao script de teste
RUN chmod +x /docker-entrypoint-initdb.d/backup.sh /usr/local/bin/test.sh

# Configure a extensão PostGIS
COPY postgis.sql /docker-entrypoint-initdb.d/postgis.sql

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
CMD postgres_exporter --log.level=info & docker-entrypoint.sh postgres & /usr/local/bin/test.sh
