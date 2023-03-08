#!/usr/bin/env bash

JSQSH_CSV="-n -v headers=false -v footers=false"

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh

list_tables() {
    local LOC=${1:-SRC}
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
    local DB_SCHEMA=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_SQL="SELECT table_name FROM information_schema.tables where table_type='BASE TABLE' and table_schema='${DB_SCHEMA}' order by table_name;"
        ;;
        postgresql|sqlserver)
    local DB_CATALOG=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_name FROM information_schema.tables where table_type='BASE TABLE' and table_schema='${DB_SCHEMA}' and table_catalog='${DB_CATALOG}' order by table_name;"
        ;;
    *)
        echo "$0: ${DB_TYPE,,} needs to be handled."
        ;;
    esac
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV"
    fi
}

list_columns() {
    local LOC="${1:-SRC}"        # SRC|DST
    local TABLE_NAME="${2:-usertable}"    # usertable|sbtest1
    local REMOVE_COLS=${3:-ts2}

    # use parameter expansion https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    local DB_HOST=$( x="${LOC^^}DB_HOST"; echo ${!x} )
    local DB_PORT=$( x="${LOC^^}DB_PORT"; echo ${!x} )
    local DB_ARC_USER=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_ARC_PW=$( x="${LOC^^}DB_ARC_PW"; echo ${!x} )
    local DB_TYPE=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_JSQSH_DRIVER=$( x="${LOC^^}DB_JSQSH_DRIVER"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
            DB_SQL="SELECT column_name FROM information_schema.columns WHERE table_schema='${DB_ARC_USER}' and table_name='${TABLE_NAME}' order by column_name;"
            ;;
        postgresql|sqlserver)
            DB_SQL="SELECT column_name FROM information_schema.columns WHERE table_catalog='${DB_ARC_USER}' and table_schema='${DB_SCHEMA}' and table_name='${TABLE_NAME}' order by column_name;"
            
            ;;
        *)
            echo "$0: ${DB_TYPE,,} needs to be handled."
            ;;
    esac

    # grab the column names
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v "^${REMOVE_COLS}"
    fi
}

dump_table() {
    local LOC="${1:-SRC}"        # SRC|DST
    local TABLE_NAME="${2:-usertable}"    # usertable|sbtest1
    local REMOVE_COLS=${3:-ts2}

    # use parameter expansion https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    local DB_HOST=$( x="${LOC^^}DB_HOST"; echo ${!x} )
    local DB_PORT=$( x="${LOC^^}DB_PORT"; echo ${!x} )
    local DB_ARC_USER=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_ARC_PW=$( x="${LOC^^}DB_ARC_PW"; echo ${!x} )
    local DB_TYPE=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_JSQSH_DRIVER=$( x="${LOC^^}DB_JSQSH_DRIVER"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)            
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_schema='${DB_ARC_USER}' AND Col.table_name='${TABLE_NAME}' order by Col.ordinal_position; -m csv"
            ;;
        postgresql|sqlserver)            
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_catalog='${DB_ARC_USER}' AND Col.table_schema='${DB_SCHEMA}' AND Col.table_name='${TABLE_NAME}' order by Col.ordinal_position; -m csv"
            ;;
        *)
            echo "$0: ${DB_TYPE,,} needs to be handled."
            ;;
    esac

    # grab the column names
    col_names=$( echo ${col_name_sql} | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" | grep -v ${REMOVE_COLS} | paste -s -d, )
    col_names_pk=$( echo ${col_pk_sql} | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" | grep -v ${REMOVE_COLS} | paste -s -d, )

    # show the column names to be validated
    echo "${X} select $col_names from $TABLE_NAME order by $col_names_pk;"
    
    # dump the table in CSV
    echo "select $col_names from $TABLE_NAME order by $col_names_pk; -m csv" | jdbc_cli_${X,,} "-n -v headers=false -v footers=false" > ${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.tsv 
}

# dump the tables common to both src and dst
dump_tables() {
    list_tables src > /tmp/validate.src_tables.$$
    list_tables dst > /tmp/validate.dst_tables.$$
    for t in $( comm -12 /tmp/validate.src_tables.$$ /tmp/validate.dst_tables.$$ ); do
        echo $t
        list_columns src $t > /tmp/validate.src_$t.$$ 
        list_columns dst $t > /tmp/validate.dst_$t.$$
        # save fields in bash array
        cols=( $(comm -12 /tmp/validate.src_$t.$$ /tmp/validate.dst_$t.$$) )
        for c in "${cols[@]}"; do echo $c; done
    #dump_table sbtest1 src
    #dump_table usertable src
    #dump_table sbtest1 dst
    #dump_table usertable dst
    done
    rm /tmp/validate.*.$$
}

# run the diff
diff_tables() {
    for TABLE_NAME in sbtest1 usertable; do
        echo ls ${CFG_DIR}/*.${TABLE_NAME}.tsv \| xargs diff 
        ls ${CFG_DIR}/*.${TABLE_NAME}.tsv | xargs diff | head -n 10
        #> ${CFG_DIR}.${TABLE_NAME}.diff
    done
}

sourced="0"
if [ -n "$ZSH_VERSION" ]; then 
case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
[ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
(return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames.
# Detects `sh` and `dash`; add additional shell filenames as needed.
case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
fi

if [ "$sourced" = "0" ]; then
    dump_tables
    diff_tables
fi