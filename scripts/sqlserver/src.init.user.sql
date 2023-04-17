
-- ts is used for snapshot delta. 
CREATE TABLE theusertable (
	ycsb_key VARCHAR(255),
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts datetime DEFAULT CURRENT_TIMESTAMP,
	constraint primary key (ycsb_key),
	index ts (ts)
);

-- will only happen if source and destion was flipped
ALTER TABLE theusertable DROP COLUMN ts2;
ALTER TABLE sbtest1 DROP COLUMN ts2;
