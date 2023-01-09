-- create ycsb user account
CREATE USER IF NOT EXISTS 'ycsb'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'ycsb'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON ycsb.* to 'ycsb'@'%';
GRANT ALL ON ycsb.* to 'ycsb'@'localhost';
create database IF NOT EXISTS ycsb;

CREATE TABLE if not exists ycsb.usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT
);

GRANT ALL ON arcion.* to 'ycsb'@'%';
GRANT ALL ON arcion.* to 'ycsb'@'localhost';

-- enable arcion replicant CDC 
-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'ycsb'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'ycsb'@'%';
