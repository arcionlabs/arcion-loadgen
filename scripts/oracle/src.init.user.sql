-- create with DB:owner.tablename
CREATE TABLE replicate_io_cdc_heartbeat(
  timestamp NUMBER NOT NULL,
  PRIMARY KEY(timestamp)
);
