create user ${SRCDB_ARC_USER} with password '${SRCDB_ARC_PW}';
-- create database IF NOT EXISTS ${SRCDB_DB} with LOG;

database ${SRCDB_DB};
grant resource to ${SRCDB_ARC_USER};
grant connect to ${SRCDB_ARC_USER};


