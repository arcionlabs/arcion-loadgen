CREATE TABLE if not exists sbtest1(
	id INTEGER,
  	k INTEGER DEFAULT '0' NOT NULL,
  	c TEXT,
  	pad TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
	constraint sbtest1_pkey primary key (id)
);
CREATE INDEX ON sbtest1(ts);

-- ts is used for snapshot delta. 
CREATE TABLE if not exists theusertable (
	ycsb_key VARCHAR(255),
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
	constraint theusertable_pkey primary key (ycsb_key)
);
CREATE INDEX ON theusertable(ts);
