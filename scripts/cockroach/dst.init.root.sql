-- create user and db
CREATE USER ${DSTDB_ARC_USER}; -- PASSWORD 'password';
ALTER USER ${DSTDB_ARC_USER} CREATEDB;
CREATE DATABASE ${DSTDB_DB} WITH OWNER ${DSTDB_ARC_USER}; -- ENCODING 'UTF8';

-- not required but recommneded by cockroachdb
ALTER ROLE ${DSTDB_ARC_USER} SET copy_from_retries_enabled = true;
ALTER ROLE ${DSTDB_ARC_USER} SET copy_from_atomic_enabled = false;