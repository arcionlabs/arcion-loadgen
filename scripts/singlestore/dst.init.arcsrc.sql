-- 
-- NOTE: Arcion singlestore requires same schema on source and destination
--
CREATE rowstore TABLE if not exists sbtest1(
    id INTEGER,
    k INTEGER DEFAULT '0' NOT NULL,
    c CHAR(120) DEFAULT '' NOT NULL,
    pad CHAR(60) DEFAULT '' NOT NULL,
    primary key (id),
    ts TIMESTAMP(6),
    index(ts)
);

-- ts is used for snapshot delta. 
CREATE rowstore TABLE if not exists usertable (
    YCSB_KEY VARCHAR(255) PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    ts TIMESTAMP(6),
    index(ts2)
);