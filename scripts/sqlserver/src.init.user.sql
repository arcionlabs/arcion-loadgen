ALTER DATABASE ${SRCDB_ARC_USER} SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);
ALTER TABLE sbtest1 ENABLE CHANGE_TRACKING;
ALTER TABLE usertable ENABLE CHANGE_TRACKING;

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
CREATE TABLE replicate_io_cdc_heartbeat(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

-- ts is used for snapshot delta. 
-- mysql ignores primary_key and uses primary
-- pg and sqlserver honor the provided name
CREATE TABLE sbtest1(
	id INTEGER,
	k INTEGER DEFAULT '0' NOT NULL,
	c CHAR(120) DEFAULT '' NOT NULL,
	pad CHAR(60) DEFAULT '' NOT NULL,
	ts datetime DEFAULT CURRENT_TIMESTAMP,
	constraint sbtest1_pkey primary key (id),
	index ts (ts)
);

-- ts is used for snapshot delta. 
-- mysql ignores primary_key and uses primary
-- pg and sqlserver honor the provided name
CREATE TABLE usertable (
	ycsb_key VARCHAR(255),
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT,
	ts datetime DEFAULT CURRENT_TIMESTAMP,
	constraint usertable_pkey primary key (id),
	index ts (ts)
);

-- will only happen if source and destion was flipped
ALTER TABLE usertable DROP COLUMN ts2;
ALTER TABLE sbtest1 DROP COLUMN ts2;
