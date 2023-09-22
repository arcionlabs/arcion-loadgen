ALTER DATABASE ${SRCDB_DB} SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

alter table  access_info                         enable change_tracking;
alter table  accounts                            enable change_tracking;
alter table  added_tweets                        enable change_tracking;
alter table  area_code_state                     enable change_tracking;
alter table  call_forwarding                     enable change_tracking;
alter table  checking                            enable change_tracking;
alter table  contestants                         enable change_tracking;
alter table  cputable                            enable change_tracking;
alter table  customer                            enable change_tracking;
alter table  district                            enable change_tracking;
alter table  followers                           enable change_tracking;
alter table  follows                             enable change_tracking;
alter table  history                             enable change_tracking;
alter table  iotable                             enable change_tracking;
alter table  iotablesmallrow                     enable change_tracking;
alter table  ipblocks                            enable change_tracking;
alter table  item                                enable change_tracking;
alter table  locktable                           enable change_tracking;
alter table  logging                             enable change_tracking;
alter table  MSchange_tracking_history           enable change_tracking;
alter table  new_order                           enable change_tracking;
alter table  oorder                              enable change_tracking;
alter table  order_line                          enable change_tracking;
alter table  page                                enable change_tracking;
alter table  page_backup                         enable change_tracking;
alter table  page_restrictions                   enable change_tracking;
alter table  recentchanges                       enable change_tracking;
alter table  replicate_io_audit_ddl              enable change_tracking;
alter table  replicate_io_audit_tbl_cons         enable change_tracking;
alter table  replicate_io_audit_tbl_schema       enable change_tracking;
alter table  REPLICATE_IO_CDC_HEARTBEAT          enable change_tracking;
alter table  revision                            enable change_tracking;
alter table  savings                             enable change_tracking;
alter table  sbtest1                             enable change_tracking;
alter table  sitest                              enable change_tracking;
alter table  special_facility                    enable change_tracking;
alter table  stock                               enable change_tracking;
alter table  subscriber                          enable change_tracking;
alter table  text                                enable change_tracking;
alter table  YCSBDENSE                           enable change_tracking;
alter table  YCSBSPARSE                          enable change_tracking;
alter table  tweets                              enable change_tracking;
alter table  user_groups                         enable change_tracking;
alter table  user_profiles                       enable change_tracking;
alter table  useracct                            enable change_tracking;
alter table  usertable                           enable change_tracking;
alter table  value_backup                        enable change_tracking;
alter table  votes                               enable change_tracking;
alter table  warehouse                           enable change_tracking;
alter table  watchlist                           enable change_tracking;
alter table  v_votes_by_contestant_number_state  enable change_tracking;
alter table  v_votes_by_phone_number             enable change_tracking;


create table replicate_io_audit_ddl("CURRENT_USER" NVARCHAR(128), "SCHEMA_NAME" NVARCHAR(128), "TABLE_NAME" NVARCHAR(128), "TYPE" NVARCHAR(30), "OPERATION_TYPE" NVARCHAR(30), "SQL_TXT" NVARCHAR(2000), "LOGICAL_POSITION" BIGINT, CONSTRAINT "null.replicate_io_audit_ddlPK" PRIMARY KEY("LOGICAL_POSITION"));

CREATE TABLE replicate_io_audit_tbl_cons("SCHEMA_NAME" VARCHAR(128), "TABLE_NAME" VARCHAR(128), "COLUMN_NAME" VARCHAR(4000), "COL_POSITION" BIGINT, "CONSTRAINT_NAME" VARCHAR(128), "CONSTRAINT_TYPE" VARCHAR(1), "LOGICAL_POSITION" BIGINT);

CREATE TABLE replicate_io_audit_tbl_schema("COLUMN_ID" BIGINT, "DATA_DEFAULT" BIGINT, "COLUMN_NAME" VARCHAR(128) NOT NULL, "TABLE_NAME" NVARCHAR(128) NOT NULL, "SCHEMA_NAME" NVARCHAR(128) NOT NULL, "HIDDEN_COLUMN" NVARCHAR(3), "DATA_TYPE" NVARCHAR(128), "DATA_LENGTH" BIGINT, "CHAR_LENGTH" BIGINT, "DATA_SCALE" BIGINT, "DATA_PRECISION" BIGINT, "IDENTITY_COLUMN" NVARCHAR(3), "VIRTUAL_COLUMN" NVARCHAR(3), "NULLABLE" NVARCHAR(1), "LOGICAL_POSITION" BIGINT);

CREATE OR ALTER TRIGGER replicate_io_audit_ddl_trigger 
ON DATABASE AFTER ALTER_TABLE 
AS
BEGIN
SET NOCOUNT ON;
DECLARE @data XML
DECLARE @operation NVARCHAR(30)
SET @data = EVENTDATA()
SET @operation = @data.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(30)')
INSERT INTO
"replicate_io_audit_ddl" ("CURRENT_USER", "SCHEMA_NAME", "TABLE_NAME", "TYPE", "OPERATION_TYPE", "SQL_TXT", "LOGICAL_POSITION") VALUES (
	SUSER_NAME(),
	CONVERT(NVARCHAR(128), CURRENT_USER),
	@data.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(128)'),
	@data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(30)'),
	@data.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(30)'),
	@data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(2000)'),
	CHANGE_TRACKING_CURRENT_VERSION() 
);
END;

-- create arcsrc for retrivial
CREATE TABLE REPLICATE_IO_CDC_HEARTBEAT(
  TIMESTAMP BIGINT NOT NULL,
  PRIMARY KEY(TIMESTAMP)
);


