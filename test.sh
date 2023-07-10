#!/bin/bash

export PGUSER="$POSTGRES_USER"
RVAL=0

# Teste se o PostGIS está devidamente integrado ao PostgreSQL
psql -d $POSTGRES_DB -c "SELECT PostGIS_version();"
RVAL=$((($RVAL + $?)))

# Teste se o PostgreSQL Server Exporter está ativo
curl -s http://localhost:9187/metrics | grep -q 'postgres_exporter'
RVAL=$((($RVAL + $?)))

# Teste se o Prometheus está ativo
curl -s http://localhost:9090/-/ready | grep -q 'Prometheus'
RVAL=$((($RVAL + $?)))

# Verifique o status dos testes
if [ $RVAL -eq 0 ]; then
    echo "Testes de extensões passaram com sucesso!"
    exit 0
else
    echo "Um ou mais testes falharam!"
    exit 1
fi
