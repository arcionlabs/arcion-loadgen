
Start postgres with WAL and Replication enabled

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
```

Create source and target schemas

```sql
CREATE USER arcsrc PASSWORD 'password';
create schema arcsrc;
-- GRANT USAGE ON SCHEMA arcsrc TO arcsrc;
GRANT ALL ON SCHEMA arcsrc TO arcsrc;
ALTER ROLE arcsrc WITH REPLICATION;

CREATE USER arcdst PASSWORD 'password';
create schema arcdst;
-- GRANT USAGE ON SCHEMA arcdst TO arcdst;
GRANT ALL ON SCHEMA arcsrc TO arcdst;
ALTER ROLE arcdst WITH REPLICATION;
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
