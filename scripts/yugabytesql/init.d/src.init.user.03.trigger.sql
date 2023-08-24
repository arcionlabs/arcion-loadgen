-- source trigger
drop trigger update_ts_on_usertable_on on THEUSERTABLE;

-- could happen if used as target
drop trigger update_ts2_on_usertable_on on THEUSERTABLE;

CREATE OR REPLACE FUNCTION update_ts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.TS = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ language 'plpgsql';

drop trigger update_ts_on_usertable_on on THEUSERTABLE;
CREATE TRIGGER update_ts_on_usertable_on
    BEFORE UPDATE
    ON
        THEUSERTABLE
    FOR EACH ROW
EXECUTE PROCEDURE update_ts();


