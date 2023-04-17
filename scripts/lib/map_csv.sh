#!/usr/bin/env bash 

map_db() {
    local DB_TYPE=${1}
    local COLUMN_INDEX=${2:-2}  
    local COLUMN_VALUE
    # column position in the map.csv
    # type(1),group(2),default_port(3),root_user(4),root_pw(5)
    if [ -f "${SCRIPTS_DIR}/utils/map.csv" ]; then 
        ROW=$(grep "^${DB_TYPE}," ${SCRIPTS_DIR}/utils/map.csv | head -n 1)
        COLUMN_VALUE=$(echo ${ROW} | cut -d',' -f${COLUMN_INDEX})
    fi
    if [ -z "${ROW}" ]; then 
        echo "Error: $1 not defined in map.csv." >&2
    fi
    echo $COLUMN_VALUE
}
map_dbgrp() {
    map_db "$1" 2
}
map_dbport() {
    map_db "$1" 3
}
map_dbroot() {
    map_db "$1" 4
}
map_dbrootpw() {
    map_db "$1" 5
}

map_dbschema() {
    map_db "$1" 6
}

map_benchbase_type() {
    map_db "$1" 7
}

map_benchbase_isolation() {
    map_db "$1" 8
}

map_root_db() {
    map_db "$1" 9
}

# this is actually the profile based on hierarchy
# full host name
# first word of host name
map_dbtype() {
    local DB_HOST=${1}
    # infer srcdb type from the full name 
    local DB_TYPE=$( map_db ${DB_HOST} 1 )
    if [ ! -z "${DB_TYPE}" ]; then
        echo "$DB_TYPE inferred from full host name $DB_HOST." >&2
        echo "$DB_TYPE"
        return 0
    fi
    # infer srcdb type from the first word of host name
    local DB_HOST_FIRST_WORD=$( echo ${DB_HOST} | awk -F'[-./0123456789]' '{print $1}' )
    local DB_TYPE=$( map_db ${DB_HOST_FIRST_WORD} 1 )
    if [ ! -z "${DB_TYPE}" ]; then
        echo "$DB_TYPE inferred from group name based on hostname first word." >&2
        echo "$DB_TYPE"
        return 0
    fi

    echo "DB_TYPE could not infer from $DB_HOST." >&2
    return 1
}
