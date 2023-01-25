export SRCDB_HOST=pg-db
export SRCDB_TYPE=postgres
export DSTDB_HOST=pg-db-2
export DSTDB_TYPE=postgres


Start postgres with WAL and Replication enabled

export DSTDB_HOST=pg-db
export DSTDB_TYPE=postgres
export DSTDB_ROOT_PW=password
export DSTDB_ROOT_USER=postgres

psql postgresql://${DSTDB_ROOT_USER}:${DSTDB_ROOT_PW}@${DSTDB_HOST}/
-- list databases
\l 
-- list tables
\dt

```bash
docker run -d \
    --name pg-db \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=1
docker run -d \
    --name pg-db-2 \
    --network arcnet \
    -p :5432 \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_HOST_AUTH_METHOD=password \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=1
```

Create source and target schemas

```sql
-- src
CREATE USER arcsrc PASSWORD 'password';
ALTER USER arcsrc CREATEDB;
ALTER ROLE arcsrc WITH REPLICATION;
CREATE DATABASE arcsrc WITH OWNER arcsrc ENCODING 'UTF8';
CREATE DATABASE io WITH OWNER arcsrc ENCODING 'UTF8';


CREATE USER arcdst PASSWORD 'password';
ALTER USER arcdst CREATEDB;
ALTER ROLE arcdst WITH REPLICATION;
CREATE DATABASE arcdst WITH OWNER arcdst ENCODING 'UTF8';

psql postgresql://arcsrc:password@${DSTDB_HOST}/


-- GRANT ALL PRIVILEGES ON DATABASE arcsrc TO arcsrc;



CREATE USER arcdst PASSWORD 'password';
create schema arcdst;
create schema io;
-- GRANT USAGE ON SCHEMA arcdst TO arcdst;
GRANT ALL ON SCHEMA arcdst TO arcdst;
GRANT ALL ON SCHEMA io TO arcdst;
ALTER ROLE arcdst WITH REPLICATION;

ALTER SCHEMA io OWNER TO arcdst;
ALTER SCHEMA arcdst OWNER TO arcdst;
CREATE DATABASE arcdst WITH OWNER arcdst ENCODING 'UTF8';
```

Enable replication on `arcsrc` with `test_decoding`

```sql
SELECT 'init' FROM pg_create_logical_replication_slot('arcsrc', 'test_decoding');
SELECT * from pg_replication_slots;
```

Optional if the tables don't have primary keys

```sql
ALTER TABLE <table_name> REPLICA IDENTITY FULL;
```

create YCSB table

jsqsh --user=arcsrc --password=password pg

```sql
CREATE TABLE if not exists usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY
	,FIELD0 TEXT, FIELD1 TEXT
	,FIELD2 TEXT, FIELD3 TEXT
	,FIELD4 TEXT, FIELD5 TEXT
	,FIELD6 TEXT, FIELD7 TEXT
	,FIELD8 TEXT, FIELD9 TEXT
	--, ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL PRIMARY KEY
);
```

jsqsh commands for postgres

```sql
\show catalogs
\show schemas
\show tables
```
