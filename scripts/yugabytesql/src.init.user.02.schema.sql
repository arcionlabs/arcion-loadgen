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
CREATE TABLE if not exists usertable (
	ycsb_key VARCHAR(255),
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
	constraint usertable_pkey primary key (ycsb_key)
);
CREATE INDEX ON usertable(ts);

drop trigger update_ts_on_usertable_on on usertable;
drop trigger update_ts_on_sbtest1_on on sbtest1;

drop trigger update_ts2_on_usertable_on on usertable;
drop trigger update_ts2_on_sbtest1_on on sbtest1;

CREATE OR REPLACE FUNCTION update_ts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ts = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ language 'plpgsql';

drop trigger update_ts_on_usertable_on on sbtest1;
CREATE TRIGGER update_ts_on_usertable_on
    BEFORE UPDATE
    ON
        usertable
    FOR EACH ROW
EXECUTE PROCEDURE update_ts();

drop trigger update_ts_on_sbtest1_on on sbtest1;
CREATE TRIGGER update_ts_on_sbtest1_on
    BEFORE UPDATE
    ON
        sbtest1
    FOR EACH ROW
EXECUTE PROCEDURE update_ts();