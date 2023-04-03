create user ${SRCDB_ARC_USER} with password '${SRCDB_ARC_PW}';
create database ${SRCDB_ARC_USER} with LOG;

database ${SRCDB_DB};
-- not sure what this statement does but with it the below does not seem to take effect
-- TODO: create schema authorization ${SRCDB_ARC_USER};
grant resource to ${SRCDB_ARC_USER};
grant connect to ${SRCDB_ARC_USER};

