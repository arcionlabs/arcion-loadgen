
```bash
docker run -d \
    --name postgresql \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=10 \
    -c ssl=on \
    -c ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem \
    -c ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key    
docker exec -it postgresql sh -c "apt update && apt install -y postgresql-15-wal2json postgresql-contrib"

docker run -d \
    --name postgresql-2 \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=10 
docker exec -it postgresql-2 sh -c "apt update && apt install -y postgresql-15-wal2json postgresql-contrib"


```



```
```bash
SRCDB_HOST=postgresql DSTDB_HOST=postgresql-2 REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=postgresql DSTDB_HOST=postgresql-2 REPL_TYPE=full ./menu.sh

SRCDB_HOST=postgresql DSTDB_HOST=postgresql-2 REPL_TYPE=real-time ./menu.sh
```

not supported for now
```
SRCDB_HOST=postgresql DSTDB_HOST=postgresql-2 REPL_TYPE=delta-snapshot ./menu.sh
```

Useful psql commands
```sql
psql postgresql://${DSTDB_ROOT_USER}:${DSTDB_ROOT_PW}@${DSTDB_HOST}/
psql postgresql://postgres:password@postgresql-2/

-- list databases
\l 
-- list tables
\dt
```

Useful `jsqsh` commands for postgres
```sql
\show catalogs
\show schemas
\show tables
```

```
# Dockerfile-postgres
FROM postgres:12.3
RUN apt update && apt install -y postgresql-15-wal2json postgresql-contrib
```

SELECT 'init' FROM pg_create_logical_replication_slot('wal2json', 'wal2json');


## enable ssl with Client Certificates

https://www.howtoforge.com/postgresql-ssl-certificates

root.crt (trusted root certificate)
postgresql.crt (client certificate)
postgresql.pem (private key)
postgresql.pem.pk8 (private key for JDBC driver has format restrictions)

```bash
psql postgresql://postgres:password@postgresql/?sslmode=require

cd scripts/postgresql
mkdir certs
cd certs
# private key
openssl genrsa -des3 -passout pass:password -out postgresql.pem 1024
openssl pkcs8 -passin pass:password -passout pass:"" -topk8 -inform PEM -in postgresql.pem -outform DER -out postgresql.pem.pk8 -v1 PBE-MD5-DES

# public key (referred as ssl-key)
openssl rsa -passin pass:password -in postgresql.pem -out postgresql.pub 

# create client's csr
openssl req -new -key postgresql.pub -out postgresql.csr -subj '/C=US/ST=./L=./O=./CN=.'
# sign using server's cert
docker exec -i postgresql openssl x509 -req -CA /etc/ssl/certs/ssl-cert-snakeoil.pem -CAkey /etc/ssl/private/ssl-cert-snakeoil.key -CAcreateserial <postgresql.csr >postgresql.crt
```
