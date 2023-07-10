#!/bin/sh

# Aguardando o postgres iniciar
until pg_isready -q; do
 echo "Waiting Postgres...."
 sleep 5
done

echo "Iniciando Prometheus..."
prometheus --storage.tsdb.path /var/lib/prometheus/ --config.file /etc/prometheus/prometheus.yml &

sleep 5
echo "Iniciando postgres_exporter..."
export DATA_SOURCE_NAME="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}?sslmode=disable"
postgres_exporter --log.level=info &

sleep 5
/usr/local/bin/test.sh
