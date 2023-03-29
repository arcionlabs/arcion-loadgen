CREATE TABLE sbtest1(
	id INTEGER,
	k INTEGER DEFAULT '0' NOT NULL,
	c CHAR(120) DEFAULT '' NOT NULL,
	pad CHAR(60) DEFAULT '' NOT NULL,
	primary key (id),
	ts datetime2 DEFAULT CURRENT_TIMESTAMP,
	index ts (ts)
);

-- ts is used for snapshot delta. 
CREATE TABLE theusertable (
	ycsb_key VARCHAR(255) PRIMARY KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts datetime2 DEFAULT CURRENT_TIMESTAMP,
	index ts (ts)
);

alter table sbtest1 ADD ts2 datetime2 DEFAULT CURRENT_TIMESTAMP;
alter table theusertable ADD ts2 datetime2 DEFAULT CURRENT_TIMESTAMP;
