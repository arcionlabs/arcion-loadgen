#!/usr/bin/env bash

nativedump_tables() {
    grep "^Table " ../$LOG_ID/trace.log | awk -F'[ |(]' '{print $(NF-1)}'
}

nativedump_mysql() {

    for line in "$(nativedump_tables)"; do
        readarray -d '.' -t dbtab < <(printf '%s' "$line")
        declare -p dbtab
        time mysqldump --verbose --no-create-db --no-create-info -h ${SRCDB_HOST} --port ${SRCDB_PORT} -u ${SRCDB_ROOT} --password=${SRCDB_PW} ${dbtab[0]} ${dbtab[1]} > ${CFG_DIR}/stage/${line}.sql
        time mysqldump --verbose --no-create-db --no-create-info -h ${SRCDB_HOST} --port ${SRCDB_PORT} -u ${SRCDB_ROOT} --password=${SRCDB_PW} ${dbtab[0]} ${dbtab[1]} > /var/tmp/${line}.sql
        time mysqldump --verbose --no-create-db --no-create-info -h ${SRCDB_HOST} --port ${SRCDB_PORT} -u ${SRCDB_ROOT} --password=${SRCDB_PW} ${dbtab[0]} ${dbtab[1]} > /opt/oracle/share/${line}.sql
        time mysqldump --verbose --no-create-db --no-create-info -h ${SRCDB_HOST} --port ${SRCDB_PORT} -u ${SRCDB_ROOT} --password=${SRCDB_PW} ${dbtab[0]} ${dbtab[1]} > /dev/null
    done
}

nativedump() {
    local db_type=${db_type:-${SRCDB_TYPE}}
    local db_grp=${db_type:-${SRCDB_GRP}}

    if [ -z "${db_type,,}" ]; then
        echo "Error: db_type is not set." >&2
        return 1
    fi

    if [ -z "${db_grp,,}" ]; then
        echo "Error: db_grp is not set." >&2
        return 1
    fi

    if [ "${db_grp,,}" = "ase" ]; then nativedump_ase "$*"
    elif [ "${db_grp,,}" = "db2" ]; then nativedump_db2 "$*"
    elif [ "${db_grp,,}" = "sqlserver" ]; then nativedump_sqlserver "$*"
    elif [ "${db_grp,,}" = "informix" ]; then nativedump_informix "$*"
    elif [ "${db_grp,,}" = "oracle" ]; then nativedump_oracle "$*"
    elif [ "${db_grp,,}" = "snowflake" ]; then nativedump_snowflake "$*"
    else 
        case "${db_type,,}" in 
            mysql | mariadb | cockroach ) nativedump_mysql "$*";; 
            singlestore) nativedump_singlestore "$*";;
            yugabytesql | postgresql) nativedump_postgres "$*";;
            *) nativedump_default "$*";;
        esac
    fi
}