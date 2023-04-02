create user ${SRCDB_ARC_USER} with password '${SRCDB_ARC_PW}';
create database ${SRCDB_ARC_USER} with LOG;

database ${SRCDB_DB};
create schema authorization ${SRCDB_ARC_USER};
grant resource to ${SRCDB_ARC_USER};
grant connect to ${SRCDB_ARC_USER};

