-- create arcsrc for retrivial
CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);


-- ts is used for snapshot delta. 
CREATE TABLE if not exists theusertable (
	ycsb_key int PRIMARY KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
	index(ts)
);

CREATE TABLE unicode (
  id int unsigned NOT NULL AUTO_INCREMENT,
  str text CHARACTER SET utf8mb4,
  PRIMARY KEY (id)
) DEFAULT CHARSET=utf8mb4;

