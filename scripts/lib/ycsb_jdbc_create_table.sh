#!/usr/bin/env bash

ycsb_create_table() {
    if [ -z "${db_type,,}" ]; then
        echo "Error: db_type is not set." >&2
        return 1
    fi

    case "${db_type,,}" in

        informix)
            cat <<'EOF'
CREATE TABLE if not exists  theusertable (
	ycsb_key int PRIMARY KEY,
	field0 varchar(255), field1 varchar(255),
	field2 varchar(255), field3 varchar(255),
	field4 varchar(255), field5 varchar(255),
	field6 varchar(255), field7 varchar(255),
	field8 varchar(255), field9 varchar(255)
); 
EOF
        ;; 

        mysql | mariadb | cockroach)
            cat <<'EOF'
CREATE TABLE if not exists theusertable (
    ycsb_key int primary key,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
    ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    index (ts)
);
EOF
        ;; 
        singlestore)
            cat <<'EOF'
CREATE TABLE if not exists theusertable (
    ycsb_key int,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
    ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    key (ycsb_key) using hash,
    sort key (ts),
    shard key (ycsb_key)
);
EOF
        ;;            
        yugabytesql | postgresql)
            cat <<'EOF'
CREATE TABLE if not exists theusertable (
    ycsb_key int primary key,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
    ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX IF NOT EXISTS theusertable_ts ON theusertable(ts);

-- source trigger

CREATE OR REPLACE FUNCTION update_ts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ts = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END; $$ language 'plpgsql';

CREATE TRIGGER update_ts_on_theusertable BEFORE UPDATE ON theusertable FOR EACH ROW EXECUTE PROCEDURE update_ts();
go
EOF
        ;;
        oraee)
            cat <<'EOF'
CREATE TABLE theusertable (
    ycsb_key NUMBER primary key,
    field0 varchar2(255), field1 varchar2(255),
    field2 varchar2(255), field3 varchar2(255),
    field4 varchar2(255), field5 varchar2(255),
    field6 varchar2(255), field7 varchar2(255),
    field8 varchar2(255), field9 varchar2(255),
    ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
create index theusertable_ts on theusertable (ts);
EOF
        ;;
        *)
            cat <<'EOF'
CREATE TABLE if not exists theusertable (
    ycsb_key int primary key,
    field0 TEXT, field1 TEXT,
    field2 TEXT, field3 TEXT,
    field4 TEXT, field5 TEXT,
    field6 TEXT, field7 TEXT,
    field8 TEXT, field9 TEXT,
    ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
); 
create index if not exists on theusertable (ts);"
EOF
    ;;   
    esac
}