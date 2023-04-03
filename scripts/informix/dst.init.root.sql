create user ${DSTDB_ARC_USER} with password '${DSTDB_ARC_PW}';
create database ${DSTDB_DB} with LOG;

database ${DSTDB_DB};
-- not sure what this statement does but with it the below does not seem to take effect
-- TODO: create schema authorization ${DSTDB_ARC_USER}; 
grant connect to ${DSTDB_ARC_USER};
grant resource to ${DSTDB_ARC_USER};