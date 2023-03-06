-- create arcsrc for retrivial
CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

CREATE TABLE if not exists sbtest1(
	id INTEGER,
	k INTEGER DEFAULT '0' NOT NULL,
	c CHAR(120) DEFAULT '' NOT NULL,
	pad CHAR(60) DEFAULT '' NOT NULL,
	primary key (id),
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
	index(ts)
);

drop table usertable;
CREATE TABLE usertable (
	ycsb_key VARCHAR(255) primary KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    ycsb_id bigint GENERATED ALWAYS AS (substring(ycsb_key,5)),
	index(ts),
	unique key (ycsb_id)
);

