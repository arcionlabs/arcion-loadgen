
-- ts is used for snapshot delta. 
CREATE TABLE theusertable (
	ycsb_key int,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts datetime DEFAULT CURRENT_TIMESTAMP,
	primary key (ycsb_key),
	index ts (ts)
);

