-- create sysbench user account
CREATE USER IF NOT EXISTS 'sbt'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'sbt'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON sbt.* to 'sbt'@'%';
GRANT ALL ON sbt.* to 'sbt'@'localhost';
create database IF NOT EXISTS sbt;

-- create arccion heartbeat 

GRANT ALL ON arcion.* to 'sbt'@'%';
GRANT ALL ON arcion.* to 'sbt'@'localhost';

-- enable arcion replicant CDC 
-- these grants cannot be limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'sbt'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'sbt'@'%';