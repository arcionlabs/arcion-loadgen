-- ts is used for snapshot delta/
CREATE TABLE if not exists theusertable (
    ycsb_key int,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
	key (ts) using hash,
    sort key (ycsb_key),
    shard key (ycsb_key)
);
