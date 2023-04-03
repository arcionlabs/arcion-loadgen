
-- ts is used for snapshot delta. 
CREATE TABLE if not exists  theusertable (
	ycsb_key VARCHAR(255) PRIMARY KEY,
	field0 varchar(255), field1 varchar(255),
	field2 varchar(255), field3 varchar(255),
	field4 varchar(255), field5 varchar(255),
	field6 varchar(255), field7 varchar(255),
	field8 varchar(255), field9 varchar(255)
);

-- will only happen if source and destion was flipped
ALTER TABLE theusertable DROP (ts2);
