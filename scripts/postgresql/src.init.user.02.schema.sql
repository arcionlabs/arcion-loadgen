

-- ts is used for snapshot delta. 
CREATE TABLE if not exists theusertable (
	ycsb_key int,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
	constraint theusertable_pkey primary key (ycsb_key)
);
CREATE INDEX CREATE INDEX IF NOT EXISTS ON theusertable(ts);
