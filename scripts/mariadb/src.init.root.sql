-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- enable load local infile 
SET GLOBAL local_infile = 'ON';

-- arcion user
CREATE USER IF NOT EXISTS '${SRCDB_ARC_USER}'@'%' IDENTIFIED by '${SRCDB_ARC_PW}';
CREATE USER IF NOT EXISTS '${SRCDB_ARC_USER}'@'127.0.0.1' IDENTIFIED by '${SRCDB_ARC_PW}';

GRANT ALL ON ${SRCDB_DB}.* to '${SRCDB_ARC_USER}'@'%';
GRANT ALL ON ${SRCDB_DB}.* to '${SRCDB_ARC_USER}'@'127.0.0.1';

-- prevent SELECT command denied to user '${SRCDB_ARC_USER}'@'172.18.0.3' for table 'user'
GRANT SELECT ON mysql.user TO '${SRCDB_ARC_USER}'@'%';
GRANT SELECT ON mysql.user TO '${SRCDB_ARC_USER}'@'127.0.0.1';

-- prevent SELECT command denied to user '${SRCDB_ARC_USER}'@'172.18.0.3' for table 'user'
-- GRANT SELECT ON mysql.user TO '${SRCDB_ARC_USER}'@'%';
-- GRANT SELECT ON mysql.user TO '${SRCDB_ARC_USER}'@'127.0.0.1';

GRANT SELECT ON performance_schema.* TO '${SRCDB_ARC_USER}'@'%';
GRANT SELECT ON performance_schema.* TO '${SRCDB_ARC_USER}'@'127.0.0.1';

-- arcion database
create database IF NOT EXISTS ${SRCDB_DB};

-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO '${SRCDB_ARC_USER}'@'%';
GRANT REPLICATION SLAVE ON *.* TO '${SRCDB_ARC_USER}'@'%';

-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;

