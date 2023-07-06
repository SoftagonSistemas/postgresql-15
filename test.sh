#!/bin/bash

# Teste se o PostGIS está devidamente integrado ao PostgreSQL
psql -U postgres -c "SELECT PostGIS_version();"

# Teste se o PostgreSQL Server Exporter está ativo
curl -s http://localhost:9187/metrics | grep -q 'postgres_exporter'

# Teste se o Prometheus está ativo
curl -s http://localhost:9090/-/ready | grep -q 'Prometheus'

# Verifique o status dos testes
if [ $? -eq 0 ]; then
    echo "Testes de extensões passaram com sucesso!"
    exit 0
else
    echo "Um ou mais testes falharam!"
    exit 1
fi
