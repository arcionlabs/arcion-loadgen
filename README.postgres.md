
```bash
docker run -d \
    --name postgresql \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=10 
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
