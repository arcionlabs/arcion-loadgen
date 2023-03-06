-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER '${DSTDB_ARC_USER}' IDENTIFIED BY '${DSTDB_ARC_PW}';

GRANT ALL ON ${DSTDB_ARC_USER}.* to '${DSTDB_ARC_USER}';
GRANT ALL ON io_replicate.* to '${DSTDB_ARC_USER}';

-- show binlogs
show variables like "%log_bin%";
-- flush
FLUSH PRIVILEGES;

-- make default rowstore
set global default_table_type=rowstore;
SELECT @@GLOBAL.default_table_type;

-- arcion database
create database IF NOT EXISTS ${DSTDB_ARC_USER};
create database IF NOT EXISTS io_replicate;