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
map_dbtype() {
    local DB_DIR=${1}
    DB_TYPE=$( echo $DB_DIR | awk -F'[_-/.]' '{print $1}' )
    echo "${DB_TYPE}"
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
