-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER '${SRCDB_ARC_USER}' IDENTIFIED BY '${SRCDB_ARC_PW}';

GRANT ALL ON ${SRCDB_ARC_USER}.* to '${SRCDB_ARC_USER}';

-- arcion database
create database IF NOT EXISTS ${SRCDB_ARC_USER};

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;
