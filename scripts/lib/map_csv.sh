#!/usr/bin/env bash 

# return map.csv as an array
# to test:
#   declare -a array; read_csv_as_array array /scripts/utils/map.csv
#   declare -a array; read_csv_as_array array /scripts/utils/benchbase/bbtables.csv
#   echo ${array[@]} will print out the CSV content
read_csv_as_array() {
    local -n read_csv_as_array_ret=${1}
    local csv_file=${2:-${SCRIPTS_DIR}/utils/map.csv}
    mapfile -t read_csv_as_array_ret < $csv_file
}

# find a match in csv
# $1=map.csv in array
# find_in_array array pg
# find_in_array array twitter
find_in_array() {
    local -n find_in_array_input=${1}
    local match_val=${2}
    local match_index=${3:-0}

    # local variables
    declare row
    declare header

    # skip the header and check all of the rows one by one until match
    for line in "${find_in_array_input[@]:1}" ; do
        IFS=',' read -r -a row <<< ${line}
        if [ "${row[${match_index}]}" = "${match_val}" ]; then
            echo "${line}"
            # echo "${line} found in map.csv" >&2
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
find_in_array_as_dict() {
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
            return 0
        fi
    done
    return 1
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


get_profile() {
    local -n GET_PROFILE_ARRAY=${1:-PROFILE_CSV}
    local DB_HOST=${2}
    local DB_TYPE=${3}

    local DB_PROFILE
    local DB_HOST_FIRST_WORD

    # infer db type from the full name 
    if [ -n "${DB_HOST}" ]; then
        DB_PROFILE=$( find_in_array GET_PROFILE_ARRAY ${DB_HOST} 0 )
        if [ -n "${DB_PROFILE}" ]; then
            # echo "$DB_PROFILE from full host name $DB_HOST." >&2
            echo "$DB_PROFILE"
            return 0
        fi
    fi

    # infer db type from the db type
    if [ -n "${DB_TYPE}" ]; then
        DB_PROFILE=$( find_in_array GET_PROFILE_ARRAY ${DB_TYPE} 0 )
        if [ -n "${DB_PROFILE}" ]; then
            # echo "$DB_PROFILE from db type $DB_TYPE." >&2
            echo "$DB_PROFILE"
            return 0
        fi
    fi

    # infer db type from the first word of host name
    DB_HOST_FIRST_WORD=$( echo ${DB_HOST} | awk -F'[-./]' '{print $1}' )
    if [ -n "${DB_HOST_FIRST_WORD}" ]; then
        DB_PROFILE=$( find_in_array GET_PROFILE_ARRAY ${DB_HOST_FIRST_WORD} 0 )
        if [ -n "${DB_PROFILE}" ]; then
            echo "$DB_PROFILE inferred from hostname first word." >&2
            echo "$DB_PROFILE"
            return 0
        fi
    fi

    echo "DB_PROFILE could not be inferred from $DB_HOST." >&2
    return 1
}