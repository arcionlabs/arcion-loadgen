-- source trigger
drop trigger update_ts_on_ycsbsparse_on on YCSBSPARSE;

-- could happen if used as target
drop trigger update_ts2_on_ycsbsparse_on on YCSBSPARSE;

CREATE OR REPLACE FUNCTION update_ts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.TS = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ language 'plpgsql';

drop trigger update_ts_on_ycsbsparse_on on YCSBSPARSE;
CREATE TRIGGER update_ts_on_ycsbsparse_on
    BEFORE UPDATE
    ON
        YCSBSPARSE
    FOR EACH ROW
EXECUTE PROCEDURE update_ts();


