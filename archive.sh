#!/bin/bash


WALG_S3_PREFIX="s3://${AWS_S3_BUCKET}/${BACKUP_DIRECTORY}/"
WALG_COMPRESSION_METHOD=${WALG_COMPRESSION_METHOD:-brotli}
AWS_S3_FORCE_PATH_STYLE=${AWS_S3_FORCE_PATH_STYLE:-true}

# Criando $HOME/.walg.json
echo "Criando $HOME/.walg.json"

WALG_TEXT="{\"WALG_S3_PREFIX\":\"$WALG_S3_PREFIX\",\"AWS_ACCESS_KEY_ID\":\"$AWS_ACCESS_KEY_ID\",\"AWS_SECRET_ACCESS_KEY\":\"$AWS_SECRET_ACCESS_KEY\",\"AWS_ENDPOINT\":\"$AWS_ENDPOINT\",\"WALG_UPLOAD_CONCURRENCY\":\"2\",\"WALG_DOWNLOAD_CONCURRENCY\":\"2\",\"WALG_UPLOAD_DISK_CONCURRENCY\":\"2\",\"WALG_DELTA_MAX_STEPS\":\"$BACKUP_RETENTION_DAYS\",\"WALG_COMPRESSION_METHOD\":\"$WALG_COMPRESSION_METHOD\"}"

echo $WALG_TEXT > $HOME/.walg.json

# Configurações do WAL-G para a DigitalOcean Spaces

echo "Ajustando $PGDATA/postgresql.conf para archive..."
echo "Archive (S3: $AWS_ENDPOINT) -> $WALG_S3_PREFIX"
sed -ri "s/.*archive_mode = .*/archive_mode = ${ARCHIVE_MODE:-off}/" $PGDATA/postgresql.conf
sed -ri "s/.*archive_timeout = .*/archive_timeout = ${ARCHIVE_TIMEOUT:-0}/" $PGDATA/postgresql.conf
sed -ri "s/.*archive_command = .*/archive_command = 'wal-g wal-push %p'/" $PGDATA/postgresql.conf
sed -ri "s/.*restore_command = .*/restore_command = 'wal-g wal-fetch %f %p'/" $PGDATA/postgresql.conf
