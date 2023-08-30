create user ${DSTDB_ARC_USER} with password '${DSTDB_ARC_PW}';
-- create database IF NOT EXISTS ${DSTDB_DB} with LOG;

database ${DSTDB_DB};
grant connect to ${DSTDB_ARC_USER};
grant resource to ${DSTDB_ARC_USER};