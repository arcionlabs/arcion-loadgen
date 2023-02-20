
CREATE USER ${SRCDB_ARC_USER}; -- PASSWORD 'password';
ALTER USER ${SRCDB_ARC_USER} CREATEDB;
-- ALTER ROLE arcsrc WITH REPLICATION;
-- create database root;
CREATE DATABASE ${SRCDB_ARC_USER} WITH OWNER ${SRCDB_ARC_USER}; --  ENCODING 'UTF8';

-- SELECT 'init' FROM pg_create_logical_replication_slot('arcsrc', 'test_decoding');
-- SELECT * from pg_replication_slots;
