create user ${DSTDB_ARC_USER} with password '${DSTDB_ARC_PW}';
create database ${DSTDB_DB} with LOG;

database ${DSTDB_DB};
create schema authorization ${DSTDB_ARC_USER}; 
grant connect to ${DSTDB_ARC_USER};
grant resource to ${DSTDB_ARC_USER};