-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- arcion user
CREATE USER IF NOT EXISTS 'arcion'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'arcion'@'localhost' IDENTIFIED BY 'password';

GRANT ALL ON arcion.* to 'arcion'@'%';
GRANT ALL ON arcion.* to 'arcion'@'localhost';

-- arcion database
create database IF NOT EXISTS arcion;

-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'arcion'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'arcion'@'%';

-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;