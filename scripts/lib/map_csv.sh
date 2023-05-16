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

# return map.csv as an array
# to test:
#   declare -a array; read_csv array
#   echo ${array[@]} will print out the CSV content
read_csv() {
    local -n read_csv_ret=${1}
    local csv_file=${2:-${SCRIPTS_DIR}/utils/map.csv}
    mapfile -t read_csv_ret < $csv_file
}

# find a match in csv
find_in_csv() {
    local -n match_csv_array=${1}
    local match_val=${2}
    local match_index=${3:-0}

    # local variables
    declare row
    declare header

    # skip the header and check all of the rows one by one until match
    for line in "${match_csv_array[@]:1}" ; do
        IFS=',' read -r -a row <<< ${line}
        if [ "${row[${match_index}]}" = "${match_val}" ]; then
            echo "${line}"
            return 0
        fi
    done
    return 1
}


# return matching line as associative array
# $1 = name of dict that will have return value
# $2 = name of var that has csv saved as array 
# $3 = match on hte first column
# To run a test
#    declare -a array read_csv
#    declare -A ret=(); match_csv ret array oraxe
#    declare -p ret
match_csv() {
    local -n match_csv_dict=${1}
    local -n match_csv_array=${2}
    local match_val=${3}
    local match_index=${4:-0}

    # local variables
    declare row
    declare header

    # skip the header and check all of the rows one by one until match
    for line in "${match_csv_array[@]:1}" ; do
        IFS=',' read -r -a row <<< ${line}
        if [ "${row[${match_index}]}" = "${match_val}" ]; then
            # header as array
            IFS=',' read -r -a header <<< ${match_csv_array[0]}

            # combine header with the row 
            declare i=0
            for e in "${header[@]}"; do
                match_csv_dict["$e"]="${row[i]}";
                ((i++))
            done
            return
        fi
    done
}

# return header and CSV as dict
# declare -A test=(); csv_as_dict test "${array[0]}" "$(find_csv array xxx)"

csv_as_dict() {
    local -n csv_as_dict_ret=${1}
    local csv_as_dict_header="$2"
    local csv_as_dict_row="$3"

    IFS=',' read -r -a header <<< ${csv_as_dict_header}
    IFS=',' read -r -a row <<< ${csv_as_dict_row}
    declare i=0
    for e in "${header[@]}"; do 
        csv_as_dict_ret["$e"]="${row[i]}" 
        ((i++)) 
    done
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

map_sid() {
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
