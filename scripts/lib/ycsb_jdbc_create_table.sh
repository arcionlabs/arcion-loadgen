#!/usr/bin/env bash

ycsb_create_db2() {
echo "ycsb create db2" >&2    
cat <<'EOF'
-- TS is used for snapshot delta. 
CREATE TABLE THEUSERTABLE (
	YCSB_KEY INTEGER NOT NULL PRIMARY KEY,
	FIELD0 VARCHAR(255), FIELD1 VARCHAR(255),
	FIELD2 VARCHAR(255), FIELD3 VARCHAR(255),
	FIELD4 VARCHAR(255), FIELD5 VARCHAR(255),
	FIELD6 VARCHAR(255), FIELD7 VARCHAR(255),
	FIELD8 VARCHAR(255), FIELD9 VARCHAR(255),
	TS TIMESTAMP GENERATED ALWAYS FOR EACH ROW
        ON UPDATE AS ROW CHANGE TIMESTAMP NOT NULL
);
create index THEUSERTABLE_TS on THEUSERTABLE (TS);
EOF
}

ycsb_create_sybase() {
echo "ycsb create sqlserver" >&2    
cat <<'EOF'
-- TS is used for snapshot delta. 
CREATE TABLE THEUSERTABLE (
	YCSB_KEY INT,
	FIELD0 varchar(255) default null, FIELD1 varchar(255) default null,
	FIELD2 varchar(255) default null, FIELD3 varchar(255) default null,
	FIELD4 varchar(255) default null, FIELD5 varchar(255) default null,
	FIELD6 varchar(255) default null, FIELD7 varchar(255) default null,
	FIELD8 varchar(255) default null, FIELD9 varchar(255) default null,
	PRIMARY KEY (YCSB_KEY)
);
EOF
}

ycsb_create_sqlserver() {
echo "ycsb create sqlserver" >&2    
cat <<'EOF'
-- TS is used for snapshot delta. 
CREATE TABLE THEUSERTABLE (
	YCSB_KEY INT,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT,
	PRIMARY KEY (YCSB_KEY),
);
EOF
}

ycsb_create_informix() {
echo "ycsb create informix" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS  THEUSERTABLE (
	YCSB_KEY INT PRIMARY KEY,
	FIELD0 VARCHAR(255), FIELD1 VARCHAR(255),
	FIELD2 VARCHAR(255), FIELD3 VARCHAR(255),
	FIELD4 VARCHAR(255), FIELD5 VARCHAR(255),
	FIELD6 VARCHAR(255), FIELD7 VARCHAR(255),
	FIELD8 VARCHAR(255), FIELD9 VARCHAR(255)
); 
EOF
}

ycsb_create_oracle() {
echo "ycsb create oracle" >&2    
cat <<'EOF'
CREATE TABLE THEUSERTABLE (
    YCSB_KEY NUMBER PRIMARY KEY,
    FIELD0 VARCHAR2(255), FIELD1 VARCHAR2(255),
    FIELD2 VARCHAR2(255), FIELD3 VARCHAR2(255),
    FIELD4 VARCHAR2(255), FIELD5 VARCHAR2(255),
    FIELD6 VARCHAR2(255), FIELD7 VARCHAR2(255),
    FIELD8 VARCHAR2(255), FIELD9 VARCHAR2(255),
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX THEUSERTABLE_TS ON THEUSERTABLE (TS);
EOF
}

ycsb_create_mysql() {
echo "ycsb ${db_type} ${db_grp} create mysql syntax" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX (TS)
);
EOF
}

ycsb_create_singlestore() {
echo "ycsb create singlestore" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    KEY (YCSB_KEY) USING HASH,
    SORT KEY (TS),
    SHARD KEY (YCSB_KEY)
);
EOF
}

ycsb_create_snowflake() {
echo "ycsb create snowflake" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT
); 
EOF
}

ycsb_create_postgres() {
echo "ycsb create postgres" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX IF NOT EXISTS THEUSERTABLE_TS ON THEUSERTABLE(TS);

-- SOURCE TRIGGER

CREATE OR REPLACE FUNCTION UPDATE_TS()
RETURNS TRIGGER AS $$
BEGIN
    NEW.TS = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END; 
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER UPDATE_TS_ON_THEUSERTABLE BEFORE UPDATE ON THEUSERTABLE FOR EACH ROW EXECUTE PROCEDURE UPDATE_TS();
go
EOF
}

ycsb_create_default() {
echo "ycsb create default" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX IF NOT EXISTS ON THEUSERTABLE (TS);"
EOF
}

ycsb_create_table() {
    if [ -z "${db_type,,}" ]; then
        echo "Error: db_type is not set." >&2
        return 1
    fi

    if [ -z "${db_grp,,}" ]; then
        echo "Error: db_grp is not set." >&2
        return 1
    fi

    if [ "${db_grp,,}" = "db2" ]; then ycsb_create_db2
    elif [ "${db_grp,,}" = "sqlserver" ] ||  [ "${db_grp,,}" = "sybasease" ]; then ycsb_create_sqlserver
    elif [ "${db_grp,,}" = "informix" ]; then ycsb_create_informix
    elif [ "${db_grp,,}" = "oracle" ]; then ycsb_create_oracle
    elif [ "${db_grp,,}" = "snowflake" ]; then ycsb_create_snowflake
    else 
        case "${db_type,,}" in 
            mysql | mariadb | cockroach) ycsb_create_mysql ;; 
            singlestore) ycsb_create_singlestore ;;
            yugabytesql | postgresql) ycsb_create_postgres ;;
            *) ycsb_create_default ;;
        esac
    fi
}