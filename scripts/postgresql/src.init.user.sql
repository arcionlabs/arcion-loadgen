SELECT 'init' FROM pg_create_logical_replication_slot('${SRCDB_ARC_USER}_td', 'test_decoding');
SELECT 'init' FROM pg_create_logical_replication_slot('${SRCDB_ARC_USER}_w2j', 'wal2json');
SELECT * from pg_replication_slots;

CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

CREATE TABLE if not exists sbtest1(
	id INTEGER,
  	k INTEGER DEFAULT '0' NOT NULL,
  	c TEXT DEFAULT '' NOT NULL,
  	pad TEXT DEFAULT '' NOT NULL,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
	PRIMARY KEY (id)
);

-- ts is used for snapshot delta. 
CREATE TABLE if not exists usertable (
	ycsb_key VARCHAR(255) PRIMARY KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
);