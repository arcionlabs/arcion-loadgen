-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER 'arcsrc' IDENTIFIED BY 'password';

GRANT ALL ON arcsrc.* to 'arcsrc';

-- arcion database
create database IF NOT EXISTS arcsrc;

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;

-- create arcsrc for retrivial
CREATE ROWSTORE TABLE if not exists arcsrc.replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

CREATE ROWSTORE TABLE if not exists arcsrc.sbtest1(
	id INTEGER,
	k INTEGER DEFAULT '0' NOT NULL,
	c CHAR(120) DEFAULT '' NOT NULL,
	pad CHAR(60) DEFAULT '' NOT NULL,
	primary key (id),
	ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	index(ts)
);

-- ts is used for snapshot delta. 
CREATE ROWSTORE TABLE if not exists arcsrc.usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT,
	ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	index(ts)
);
