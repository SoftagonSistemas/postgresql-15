
# Imagem Docker com PostgreSQL, TimescaleDB, PostGIS e Prometheus
  
Esta imagem Docker é uma combinação poderosa que inclui o PostgreSQL, TimescaleDB, PostGIS e Prometheus. Ela fornece uma plataforma pronta para uso para armazenar e analisar dados temporais e espaciais, com suporte a coleta de métricas através do Prometheus.
 - [Timescale](https://docs.timescale.com/getting-started/latest/)
 - [PostGis](https://postgis.net/documentation/getting_started/)
 - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
 - [WAL-G](https://wal-g.readthedocs.io/#examples)

## Recursos
 
- PostgreSQL versão 15 com TimescaleDB integrado.
- Extensão PostGIS para armazenamento e análise de dados espaciais.
- Prometheus para coleta de métricas do PostgreSQL.
- Script de backup diário usando o WAL-G.
- Configurações personalizadas do Prometheus e backup diário configurado.

## Variáveis de Ambiente

A imagem Docker aceita as seguintes variáveis de ambiente para configurar o PostgreSQL:  

-  `POSTGRES_USER`: Define o nome de usuário do PostgreSQL. O valor padrão é `postgres`.

-  `POSTGRES_PASSWORD`: Define a senha do usuário do PostgreSQL. O valor padrão é uma senha aleatória gerada automaticamente.

-  `POSTGRES_DB`: Define o nome do banco de dados a ser criado. O valor padrão é `postgres`.

-  `POSTGRES_INITDB_ARGS`: Argumentos adicionais a serem passados para o comando `initdb`.

-  `POSTGRES_HOST_AUTH_METHOD`: Define o método de autenticação do host. O valor padrão é `md5` (autenticação baseada em senha).

-  `PGDATA`: Define o diretório de dados do PostgreSQL. O valor padrão é `/var/lib/postgresql/data`.

-  `AWS_ENDPOINT`: Define o endpoint do serviço S3 da AWS. O valor padrão é `s3.amazonaws.com`.

-  `AWS_S3_BUCKET`: Define o nome do bucket S3 onde os backups serão salvos. O valor padrão é `your-bucket-name`.

-  `AWS_ACCESS_KEY_ID`: Define a chave de acesso da conta AWS. O valor padrão é `your-access-key`.

-  `AWS_SECRET_ACCESS_KEY`: Define a chave secreta da conta AWS. O valor padrão é `your-secret-key`.

-  `BACKUP_RETENTION_DAYS`: Define o número de dias de retenção dos backups. O valor padrão é `7`.

-  `BACKUP_DIRECTORY`: Define o diretório de backup. O valor padrão é `/backups`.


Consulte a documentação do PostgreSQL para obter informações mais detalhadas sobre essas variáveis de ambiente.


## Como usar
1. Criar um arquivo docker-compose.yml com o conteúdo abaixo e digitar `docker-compose up` :

     ```
     version: "3"
    services:
	    softagon-db:
	    	image: softagon/postgresql-15:latest
	    	environment:
	    	- POSTGRES_USER=myuser
	    	- POSTGRES_PASSWORD=mypassword
	    	- POSTGRES_DB=mydatabase
	    	- AWS_ENDPOINT=s3.amazonaws.com
	    	- AWS_S3_BUCKET=my-bucket
	    	- AWS_ACCESS_KEY_ID=my-access-key
	    	- AWS_SECRET_ACCESS_KEY=my-secret-key
	    	- BACKUP_RETENTION_DAYS=7
	    	- BACKUP_DIRECTORY=/backups
	    	volumes:
	    	- ./data:/var/lib/postgresql/data
	    	- ./backup:/backups
	    	ports:
	    	- 5432:5432
	    	- 9090:9090
	    	- 9187:9187
### Portas
A porta 9090 é do Prometheus, a 9187 é do postgres_exporter que deve ser usado junto ao Prometheus, você poderia conferir se está em pleno funcionamento visitando http://localhost:9090/targets

## Contribuição
Este projeto é de código aberto, gerenciado pela [Softagon Sistemas](https://softagon.com.br) e você é encorajado a contribuir. Sinta-se à vontade para enviar problemas, solicitações de recursos ou pull requests.