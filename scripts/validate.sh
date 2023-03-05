#!/usr/bin/env bash

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh

col_name_sql="SELECT column_name FROM information_schema.columns WHERE table_name='sbtest1' order by ordinal_position; -m csv"

dump_table() {
    local TABLE_NAME="$1"    # usertable|sbtest1
    local X="$2"        # SRC|DST
    local REMOVE_COLS=${3:-ts2}

    # use parameter expansion https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    local DB_HOST=$( x="${X^^}DB_HOST"; echo ${!x} )
    local DB_PORT=$( x="${X^^}DB_PORT"; echo ${!x} )
    local DB_ARC_USER=$( x="${X^^}DB_ARC_USER"; echo ${!x} )
    local DB_ARC_PW=$( x="${X^^}DB_ARC_PW"; echo ${!x} )
    local DB_TYPE=$( x="${X^^}DB_GRP"; echo ${!x} )
    local DB_GRP=$( x="${X^^}DB_GRP"; echo ${!x} )
    local DB_SCHEMA=$( x="${X^^}DB_SCHEMA"; echo ${!x} )
    local DB_JSQSH_DRIVER=$( x="${X^^}DB_JSQSH_DRIVER"; echo ${!x} )

    case ${DB_TYPE,,} in
        mysql|mariadb|singlestore)
            col_name_sql="SELECT column_name FROM information_schema.columns WHERE table_schema='${DB_ARC_USER}' and table_name='${TABLE_NAME}' order by ordinal_position; -m csv"
            
            col_pk_sql="SELECT column_name FROM information_schema.key_column_usage WHERE constraint_name='primary' and table_schema='${DB_ARC_USER}' and table_name='${TABLE_NAME}' order by ordinal_position; -m csv"
            ;;
        postgresql|cockroach|sqlserver)
            col_name_sql="SELECT column_name FROM information_schema.columns WHERE table_catalog='${DB_ARC_USER}' and table_schema='${DB_SCHEMA}' and table_name='${TABLE_NAME}' order by ordinal_position; -m csv"
            
            col_pk_sql="SELECT column_name FROM information_schema.key_column_usage WHERE constraint_name='${TABLE_NAME}_pkey'and table_catalog='${DB_ARC_USER}' and table_schema='${DB_SCHEMA}' and table_name='${TABLE_NAME}' order by ordinal_position; -m csv"
            ;;
        *)
            echo "$0: ${DB_TYPE,,} needs to be handled."
            ;;
    esac

    # grab the column names
    col_names=$( echo ${col_name_sql} | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" | grep -v ${REMOVE_COLS} | paste -s -d, )
    col_names_pk=$( echo ${col_pk_sql} | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" | grep -v ${REMOVE_COLS} | paste -s -d, )

    # show the column names to be validated
    echo "${X} select $col_names from $TABLE_NAME;"

    # dump the table in CSV
    echo "select $col_names from $TABLE_NAME; -m csv" | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" > ${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.tsv 
}

# dump the table
dump_table sbtest1 src
dump_table usertable src
dump_table sbtest1 dst
dump_table usertable dst

# run the diff
for TABLE_NAME in sbtest1 usertable; do
    echo ls ${CFG_DIR}/*.${TABLE_NAME}.tsv \| xargs diff 
    ls ${CFG_DIR}/*.${TABLE_NAME}.tsv | xargs diff | head -n 10
    #> ${CFG_DIR}.${TABLE_NAME}.diff
done
