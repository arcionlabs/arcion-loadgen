-- arcion user
CREATE USER IF NOT EXISTS 'arcsrc'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
CREATE USER IF NOT EXISTS 'arcsrc'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

GRANT ALL ON arcsrc.* to 'arcsrc'@'%';
GRANT ALL ON arcsrc.* to 'arcsrc'@'localhost';

GRANT ALL ON io_replicate.* to 'arcsrc'@'%';
GRANT ALL ON io_replicate.* to 'arcsrc'@'localhost';

-- prevent SELECT command denied to user 'arcsrc'@'172.18.0.3' for table 'user'
GRANT SELECT ON mysql.user TO 'arcsrc'@'%';
GRANT SELECT ON mysql.user TO 'arcsrc'@'localhost';

GRANT SELECT ON performance_schema.* TO 'arcsrc'@'%';
GRANT SELECT ON performance_schema.* TO 'arcsrc'@'localhost';

-- arcion database
create database IF NOT EXISTS arcsrc;
create database IF NOT EXISTS io_replicate;

-- if source has catalog.scham support
GRANT ALL ON arcsrc_public.* to 'arcsrc'@'%';
GRANT ALL ON arcsrc_public.* to 'arcsrc'@'localhost';
create database IF NOT EXISTS arcsrc_public;