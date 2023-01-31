
```bash
docker run -d \
    --name postgresql \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=1
docker run -d \
    --name postgresql-2 \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=1
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
