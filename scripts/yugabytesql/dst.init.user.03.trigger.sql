drop trigger update_ts_on_usertable_on on theusertable;
drop trigger update_ts_on_sbtest1_on on sbtest1;

drop trigger update_ts2_on_usertable_on on theusertable;
drop trigger update_ts2_on_sbtest1_on on sbtest1;

CREATE OR REPLACE FUNCTION update_ts2()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ts2 = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ts2_on_usertable_on
    BEFORE UPDATE
    ON
        theusertable
    FOR EACH ROW
EXECUTE PROCEDURE update_ts2();

CREATE TRIGGER update_ts2_on_sbtest1_on
    BEFORE UPDATE
    ON
        sbtest1
    FOR EACH ROW
EXECUTE PROCEDURE update_ts2();
