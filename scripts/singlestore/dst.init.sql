-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER 'arcsrc' IDENTIFIED BY 'password';

GRANT ALL ON arcsrc.* to 'arcsrc';
GRANT ALL ON io_replicate.* to 'arcsrc';

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;


-- arcion database
create database IF NOT EXISTS arcsrc;
create database IF NOT EXISTS io_replicate;