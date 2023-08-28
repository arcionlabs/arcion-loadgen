-- CREATE WITH DB:OWNER.TABLENAME
CREATE TABLE REPLICATE_IO_CDC_HEARTBEAT(
  TIMESTAMP NUMBER NOT NULL,
  PRIMARY KEY(TIMESTAMP)
);

-- for external tables
CREATE OR REPLACE DIRECTORY csv_data_dir AS '/opt/oracle/share';
CREATE OR REPLACE DIRECTORY csv_log_dir AS '/opt/oracle/share';
-- for exp / imp
create OR REPLACE DIRECTORY SHARED_STAGE as '/opt/oracle/share';
