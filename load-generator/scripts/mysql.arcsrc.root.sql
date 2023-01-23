-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER IF NOT EXISTS 'arcsrc'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'arcsrc'@'localhost' IDENTIFIED BY 'password';

GRANT ALL ON arcsrc.* to 'arcsrc'@'%';
GRANT ALL ON arcsrc.* to 'arcsrc'@'localhost';

-- arcion database
create database IF NOT EXISTS arcsrc;

-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'arcsrc'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'arcsrc'@'%';

-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;

CREATE TABLE if not exists arcsrc.replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

-- ts is used for snapshot delta. 
CREATE TABLE if not exists arcsrc.usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT,
	ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	index(ts)
);
