-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER 'arcdst' IDENTIFIED BY 'password';

GRANT ALL ON arcdst.* to 'arcdst';
GRANT ALL ON io_replicate.* to 'arcdst';

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;


-- arcion database
create database IF NOT EXISTS arcdst;
create database IF NOT EXISTS io_replicate;