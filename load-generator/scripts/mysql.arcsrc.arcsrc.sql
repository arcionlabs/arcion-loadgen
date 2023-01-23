-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER IF NOT EXISTS 'arcion'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'arcion'@'localhost' IDENTIFIED BY 'password';

GRANT ALL ON arcion.* to 'arcion'@'%';
GRANT ALL ON arcion.* to 'arcion'@'localhost';

-- arcion database
create database IF NOT EXISTS arcion;

-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'arcion'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'arcion'@'%';

-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;

CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

-- create ycsb user account

-- ts is used for snapshot delta. will be expensive for OLTP incurring full table scan
CREATE TABLE if not exists usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT,
	ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE if not exists replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);