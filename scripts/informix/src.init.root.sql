create user ${SRCDB_ARC_USER} with password '${SRCDB_ARC_PW}';
create database IF NOT EXISTS ${SRCDB_DB} with LOG;

database ${SRCDB_DB};
grant resource to ${SRCDB_ARC_USER};
grant connect to ${SRCDB_ARC_USER};

-- create with DB:owner.tablename
CREATE TABLE if not exists ${SRCDB_DB}:${SRCDB_SCHEMA}.replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
) LOCK MODE ROW;

