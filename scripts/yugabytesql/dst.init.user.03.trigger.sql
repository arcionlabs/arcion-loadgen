drop trigger update_ts_on_usertable_on on THEUSERTABLE;

drop trigger update_ts2_on_usertable_on on THEUSERTABLE;

CREATE OR REPLACE FUNCTION update_ts2()
RETURNS TRIGGER AS $$
BEGIN
    NEW.TS2 = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ts2_on_usertable_on
    BEFORE UPDATE
    ON
        THEUSERTABLE
    FOR EACH ROW
EXECUTE PROCEDURE update_ts2();

