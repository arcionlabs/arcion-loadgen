-- source trigger
drop trigger update_ts_on_usertable_on on usertable;
drop trigger update_ts_on_sbtest1_on on sbtest1;

-- could happen if used as target
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