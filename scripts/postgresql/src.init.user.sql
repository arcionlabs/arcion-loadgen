-- required for CDC
SELECT 'init' FROM pg_create_logical_replication_slot('${SRCDB_DB}_w2j', 'wal2json');
SELECT * from pg_replication_slots;

-- force upper case
CREATE TABLE IF NOT EXISTS "REPLICATE_IO_CDC_HEARTBEAT"(
  TIMESTAMP BIGINT NOT NULL,
  PRIMARY KEY(TIMESTAMP)
);

-- required for stream replication
alter table  customer                    replica identity full;
alter table  district                    replica identity full;
alter table  history                     replica identity full;
alter table  item                        replica identity full;
alter table  new_order                   replica identity full;
alter table  oorder                      replica identity full;
alter table  order_line                  replica identity full;
alter table  stock                       replica identity full;
alter table  theusertable                replica identity full;
alter table  warehouse                   replica identity full;