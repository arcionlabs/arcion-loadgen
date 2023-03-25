#!/usr/bin/env bash

export JSQSH_CSV="-n -v headers=false -v footers=false"

jdbc_cli() { 
  ${JSQSH_DIR}/*/bin/jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_user}" --password="${db_pw}" --server="${db_host}" --port="${db_port}" --database="${db_user}" 2>&1
}

jdbc_cli_src() {
  local db_host="${SRCDB_HOST}"  
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_port="${SRCDB_PORT}"
  local jsqsh_driver="${SRCDB_JSQSH_DRIVER}"

  jdbc_cli "$*"
}

jdbc_cli_dst() {
  local db_host="${DSTDB_HOST}"  
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_port="${DSTDB_PORT}"
  local jsqsh_driver="${DSTDB_JSQSH_DRIVER}"

  jdbc_cli "$*"
}

list_tables() {
    local LOC=${1:-SRC}
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
    local DB_SCHEMA=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_SQL="SELECT table_type, table_name FROM information_schema.tables where table_type in ('BASE TABLE','VIEW') and table_schema='${DB_SCHEMA}' order by table_name;"
        ;;
        postgresql|sqlserver)
    local DB_CATALOG=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_type, table_name FROM information_schema.tables where table_type in ('BASE TABLE','VIEW') and table_schema='${DB_SCHEMA}' and table_catalog='${DB_CATALOG}' order by table_name;"
        ;;
    *)
        echo "jdbc_cli: ${DB_GRP,,} needs to be handled."
        ;;
    esac
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | sed 's/^BASE TABLE/TABLE/'
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
            echo "jdbc_cli: ${DB_GRP,,} needs to be handled."
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
    local col_names=${3:-$( list_columns $LOC $TABLE_NAME | sort | paste -s -d, )}
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
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_schema='${DB_ARC_USER}' AND Col.table_name='${TABLE_NAME}' order by Col.ordinal_position;"
            ;;
        postgresql|sqlserver)            
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_catalog='${DB_ARC_USER}' AND Col.table_schema='${DB_SCHEMA}' AND Col.table_name='${TABLE_NAME}' order by Col.ordinal_position;"
            ;;
        *)
            echo "$0: ${DB_TYPE,,} needs to be handled."
            ;;
    esac

    col_names_pk=$( echo "${col_pk_sql}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v ${REMOVE_COLS} | paste -s -d, )

    # if there is no primary key, then just sort by all of the columns
    if [ -z "${col_names_pk}" ]; then 
        # show the column names to be validated
        echo "${LOC} select ${col_names} from $TABLE_NAME $col_names_pk;"        
        # dump the table in CSV
        echo "select ${col_names} from $TABLE_NAME $col_names_pk; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | sort > ${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.tsv 
    else 
        # show the column names to be validated
        col_names_pk="order by ${col_names_pk}"
        echo "${LOC} select ${col_names} from $TABLE_NAME $col_names_pk;"        
        # dump the table in CSV
        echo "select ${col_names} from $TABLE_NAME $col_names_pk; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" > ${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.tsv 
    fi
    echo "${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.tsv" >&2 
}

# drop all tables first.  
# repeat to drop tables without constraints first
drop_all_tables() {
    local LOC=${1:-src}
    list_tables $LOC > /tmp/tables.$$.txt
    while (( "$( cat /tmp/tables.$$.txt | wc -l )" > 0 )); do
        cat /tmp/tables.$$.txt | sed -e 's/BASE TABLE/TABLE/' -e 's/,/ /' | xargs -I xxx echo  "drop xxx;" | jdbc_cli_$LOC
        list_tables $LOC > /tmp/tables.$$.txt
    done
}

count_all_tables() {
    local LOC=${1:-src}
    rm /tmp/tables.count.$$.txt 2>/dev/null
    list_tables $LOC | sed -e 's/BASE TABLE/TABLE/' > /tmp/tables.$$.txt
    while IFS=, read -r type table
    do
        if [ "${type,,}" = "table" ]; then
            echo "select count(*) from $table;" >> /tmp/tables.count.$$.txt
        fi
    done < /tmp/tables.$$.txt
    cat /tmp/tables.count.$$.txt | jdbc_cli_$LOC
}