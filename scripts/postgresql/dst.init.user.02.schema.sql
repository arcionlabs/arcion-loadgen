CREATE TABLE if not exists sbtest1(
    id INTEGER,
    k INTEGER DEFAULT '0' NOT NULL,
    c TEXT,
    pad TEXT,
    primary key (id),
    ts TIMESTAMP(6)
);
create index on sbtest1 (ts);

-- ts is used for snapshot delta. 
CREATE TABLE if not exists usertable (
    ycsb_key VARCHAR(255) PRIMARY KEY,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
    ts TIMESTAMP(6)
);
create index on usertable (ts);

-- if the table was not created by this script
alter table sbtest1 ADD ts2 TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6);
alter table usertable ADD ts2 TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6);
