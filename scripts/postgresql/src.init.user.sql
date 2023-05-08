-- required for CDC
SELECT 'init' FROM pg_create_logical_replication_slot('${SRCDB_DB}_w2j', 'wal2json');
SELECT * from pg_replication_slots;

-- required for CDC
CREATE TABLE IF NOT EXISTS REPLICATE_IO_CDC_HEARTBEAT(
  TIMESTAMP BIGINT NOT NULL,
  PRIMARY KEY(TIMESTAMP)
);

