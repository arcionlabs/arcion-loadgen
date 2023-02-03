-- arcion user
CREATE USER IF NOT EXISTS 'arcdst'@'%' IDENTIFIED by 'password';
CREATE USER IF NOT EXISTS 'arcdst'@'localhost' IDENTIFIED by 'password';

GRANT ALL ON arcdst.* to 'arcdst'@'%';
GRANT ALL ON arcdst.* to 'arcdst'@'localhost';

GRANT ALL ON io_replicate.* to 'arcdst'@'%';
GRANT ALL ON io_replicate.* to 'arcdst'@'localhost';

-- prevent SELECT command denied to user 'arcdst'@'172.18.0.3' for table 'user'
GRANT SELECT ON mysql.user TO 'arcdst'@'%';
GRANT SELECT ON mysql.user TO 'arcdst'@'localhost';

GRANT SELECT ON performance_schema.* TO 'arcdst'@'%';
GRANT SELECT ON performance_schema.* TO 'arcdst'@'localhost';

-- arcion database
create database IF NOT EXISTS arcdst;
create database IF NOT EXISTS io_replicate;

-- flush
FLUSH PRIVILEGES;