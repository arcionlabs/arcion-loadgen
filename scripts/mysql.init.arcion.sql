-- enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- create arccion heartbeat 
-- enable arcion heartbeat to force flush

CREATE USER IF NOT EXISTS 'arcion'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'arcion'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON arcion.* to 'arcion'@'%';
GRANT ALL ON arcion.* to 'arcion'@'localhost';

create database IF NOT EXISTS arcion;

CREATE TABLE if not exists arcion.replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

describe arcion.replicate_io_cdc_heartbeat;



-- show binlogs
show variables like "%log_bin%";
show binary logs;
-- flush
FLUSH PRIVILEGES;