-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER 'arcsrc' IDENTIFIED BY 'password';

GRANT ALL ON arcsrc.* to 'arcsrc';

-- arcion database
create database IF NOT EXISTS arcsrc;

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;
