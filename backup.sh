#!/bin/bash

# Diretório de backup
BACKUP_DIR="$BACKUP_DIRECTORY"

# Configurações do WAL-G para a DigitalOcean Spaces
export AWS_ENDPOINT="$AWS_ENDPOINT"
export AWS_S3_BUCKET="$AWS_S3_BUCKET"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"

# Obter uma lista de todos os bancos de dados
export PGUSER="$POSTGRES_USER"
DATABASES=$(psql postgres -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d')

# Realizar o backup de cada banco de dados separadamente usando o WAL-G
for DB_NAME in $DATABASES
do
    echo "Fazendo backup do banco de dados: $DB_NAME"
    wal-g backup-push $BACKUP_DIR/$DB_NAME
done

# Limpar backups antigos
wal-g delete retain $BACKUP_RETENTION_DAYS --confirm

echo "Backup completo em: $BACKUP_DIR"
