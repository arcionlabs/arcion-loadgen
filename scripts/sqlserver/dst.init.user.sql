-- ts is used for snapshot delta. 
CREATE TABLE theusertable (
	ycsb_key int PRIMARY KEY,
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
