CREATE USER arcsrc PASSWORD 'password';
ALTER USER arcsrc CREATEDB;
ALTER ROLE arcsrc WITH REPLICATION;
CREATE DATABASE arcsrc WITH OWNER arcsrc ENCODING 'UTF8';
CREATE DATABASE io WITH OWNER arcsrc ENCODING 'UTF8';

