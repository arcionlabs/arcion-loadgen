#!/usr/bin/env bash

export JSQSH_CSV="-n -v headers=false -v footers=false"

# informix hints from https://code.activestate.com/recipes/576621/

jdbc_root_cli() { 
  local LOC="${1:-src}" # SRC|DST
  local db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
  local db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  local db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  local db_root_user=$( x="${LOC^^}DB_ROOT"; echo "${!x}" )
  local db_root_pw=$( x="${LOC^^}DB_PW"; echo "${!x}" )
  local db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" )
  local jsqsh_driver=$( x="${LOC^^}DB_JSQSH_DRIVER"; echo "${!x}" )
  local db_db=$( x="${LOC^^}DB_DB"; echo "${!x}" )
  local db_sid=$( x="${LOC^^}DB_SID"; echo "${!x}" )
  local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  local db_root_db=$( x="${LOC^^}DB_ROOT_DB"; echo "${!x}" )
  shift

  # set path specific to this DB
  . $SCRIPTS_DIR/lib/classpath.sh
  CLASSPATH=$(arcion_jdbc_jars $LOC)

  db_db=${db_db:-${db_user}}
  db_root_user=${db_root_user:-${db_user}}
  db_root_pw=${db_root_pw:-${db_pw}}

  # Not used but maybe helpful later
  # if the flag as '-n meaning batch mode'
  # if [[ "${1}" =~ (^|[^[:alnum:]_])-n([^[:alnum:]_]|$) ]]; then
  # 
  case "${db_grp,,}" in
    snowflake)
  CLASSPATH=${CLASSPATH} JSQSH_JAVA_OPTS="--add-opens java.base/java.nio=ALL-UNNAMED" jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_root_user}" --password="${db_root_pw}" --server="${db_host}" --port="${db_port}" -V "db=${db_db}" -V "warehouse=$( x="SNOW_${LOC^^}_WAREHOUSE"; echo "${!x}" )"
    ;;
    oracle)
  CLASSPATH=${CLASSPATH} JSQSH_JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false" jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_root_user}" --password="${db_root_pw}" --server="${db_host}" --port="${db_port}" --database="${db_sid}"
    ;;    
    postgresql | db2)
  CLASSPATH=${CLASSPATH} jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_root_user}" --password="${db_root_pw}" --server="${db_host}" --port="${db_port}" --database=${db_root_db}
    ;;
    *)
  CLASSPATH=${CLASSPATH} jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_root_user}" --password="${db_root_pw}" --server="${db_host}" --port="${db_port}"
    ;;
  esac  
}

jdbc_root_cli_src() {
  jdbc_root_cli src "$*"
}

jdbc_root_cli_dst() {
  jdbc_root_cli dst "$*"
}


jdbc_cli() { 
  local LOC="${1:-src}" # SRC|DST
  local db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
  local db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  local db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  local db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" )
  local jsqsh_driver=$( x="${LOC^^}DB_JSQSH_DRIVER"; echo "${!x}" )
  local db_db=$( x="${LOC^^}DB_DB"; echo "${!x}" )
  local db_schema=$( x="${LOC^^}DB_SCHEMA"; echo "${!x}" )
  local db_sid=$( x="${LOC^^}DB_SID"; echo "${!x}" )
  local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  shift

  # set path specific to this DB
  . $SCRIPTS_DIR/lib/classpath.sh
  CLASSPATH=$(arcion_jdbc_jars $LOC)

  db_db=${db_db:-${db_user}}

  # Not used but maybe helpful later
  # if the flag as '-n meaning batch mode'
  # if [[ "${1}" =~ (^|[^[:alnum:]_])-n([^[:alnum:]_]|$) ]]; then
  # 
  case "${db_grp,,}" in
    snowflake)
  CLASSPATH=${CLASSPATH} JSQSH_JAVA_OPTS="--add-opens java.base/java.nio=ALL-UNNAMED" jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_user}" --password="${db_pw}" --server="${db_host}" --port="${db_port}" --database ${db_user} -V "warehouse=$( x="SNOW_${LOC^^}_WAREHOUSE"; echo "${!x}" )"
    ;;
    oracle)
  CLASSPATH=${CLASSPATH} JSQSH_JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false" jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_user}" --password="${db_pw}" --server="${db_host}" --port="${db_port}" --database="${db_sid}"
    ;;    
    *)
  CLASSPATH=${CLASSPATH} jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_user}" --password="${db_pw}" --server="${db_host}" --port="${db_port}" --database="${db_user}"
    ;;
  esac  
}

jdbc_cli_src() {
  jdbc_cli src "$*"
}

jdbc_cli_dst() {
  jdbc_cli dst "$*"
}

# maintain case sensistivity from the output
# table, count(*) of tables
list_dbs() {
    local LOC=${1:-SRC}
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
    local DB_SCHEMA=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="SELECT table_schema, count(*) FROM information_schema.tables group by table_catalog, table_schema order by 1; -m csv"
        ;;
        postgresql|sqlserver)
    local DB_CATALOG=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_catalog, count(*) FROM information_schema.tables where table_schema = '${DB_SCHEMA}' group by table_catalog, table_schema order by 1,2; -m csv"
        ;;
        informix)
    local DB_SCHEMA=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="SELECT t.owner, count(*) FROM systables as t where t.tabid >= 100 group by t.owner; -m csv"
        ;;
        oracle)
    local DB_ARC_USER=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    #local DB_SQL="SELECT USERNAME FROM ALL_USERS where ORACLE_MAINTAINED='N' group BY USERNAME;"
    # SELECT COUNT(*) FROM USER_TABLES;
    local DB_SQL="select owner, count(table_name) from all_tables where owner='${DB_ARC_USER^^}' group by owner; -m csv"
        ;;    
        db2)
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT trim(table_schema), count(*) from SYSIBM.tables where table_schema='${DB_SCHEMA}' and table_type='BASE TABLE' group by table_schema; -m csv"
        ;;          
        snowflake)
    local DB_CATALOG=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_catalog, count(*) FROM ${DB_CATALOG}.information_schema.tables where table_schema = '${DB_SCHEMA}' group by table_catalog, table_schema order by 1,2; -m csv"
        ;;
        ase)
    local DB_CATALOG=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="\databases | awk -F'|' 'NF>1 {printf \"%s\n\",\$2}' | tr -d '[:blank:]' | grep ${DB_CATALOG}"
        ;;
    *)
        echo "jdbc_cli: ${DB_GRP,,} needs to be handled." >&2
        ;;
    esac

    echo ${DB_SQL} >&2
    if [ -n "$DB_SQL" ]; then
        echo "${DB_SQL}" | jdbc_cli_${LOC,,} "$JSQSH_CSV"
        return ${PIPESTATUS[1]}
    fi
}

# results are lower cased
list_tables() {
    local LOC=${1:-SRC}
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
    local DB_SCHEMA=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="SELECT table_type, table_name FROM information_schema.tables where table_type in ('BASE TABLE','VIEW') and table_schema='${DB_SCHEMA}' order by table_name; -m csv"
        ;;
        postgresql|sqlserver)
    local DB_CATALOG=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_type, table_name FROM information_schema.tables where table_type in ('BASE TABLE','VIEW') and table_schema='${DB_SCHEMA}' and table_catalog='${DB_CATALOG}' order by table_name; -m csv"
        ;;
        informix)
    local DB_SCHEMA=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="SELECT 'TABLE' as table_type, t.tabname as table_name FROM systables as t where t.tabtype in ('T') and t.owner='${DB_SCHEMA}' and  t.tabid >= 100 order by t.tabname; -m csv"
        ;;
        oracle)
    local DB_OWNER=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SQL="SELECT 'TABLE', table_name from user_tables; -m csv"
        ;;    
        db2)
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT 'TABLE', table_name from SYSIBM.tables where table_schema='${DB_SCHEMA}' and table_type='BASE TABLE'; -m csv"
        ;;           
        snowflake)
    local DB_CATALOG=$( x="${LOC^^}DB_DB"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_SQL="SELECT table_type, table_name FROM ${DB_CATALOG}.information_schema.tables where table_type in ('BASE TABLE','VIEW') and table_schema='${DB_SCHEMA}' and table_catalog='${DB_CATALOG}' order by table_name; -m csv"
        ;;
        ase)
    local DB_SQL="\tables --all --type table | awk -F'|' 'NF>1 {printf \"TABLE,%s,%s,%s\n\",\$4,\$2,\$3}' | tr -d '[:blank:]' | tee /tmp/tables.csv"
        ;;
    *)
        echo "jdbc_cli: ${DB_GRP,,} needs to be handled." >&2
        ;;
    esac

    echo ${DB_SQL} >&2
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | sed 's/^BASE TABLE/TABLE/'
    fi
}

dump_schema() {
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
    local DB_DB=$( x="${LOC^^}DB_DB"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
            DB_SQL="select column_name,data_type, column_default, is_nullable, character_maximum_length, numeric_precision, numeric_scale, datetime_precision from information_schema.columns WHERE table_name='${TABLE_NAME}' and table_schema='${DB_DB}' order by ordinal_position;"
            ;;
        postgresql|sqlserver)
            DB_SQL="select column_name,data_type, column_default, is_nullable, character_maximum_length, numeric_precision, numeric_scale, datetime_precision from information_schema.columns WHERE table_name='${TABLE_NAME} and table_schema='${DB_SCHEMA}' and table_catalog='${DB_DB}' order by ordinal_position;"
            ;;
        *)
            echo "jdbc_cli: dump_schema for ${DB_GRP,,} needs to be handled."
            ;;
    esac

    # grab the column names
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v -e "^${REMOVE_COLS}" > ${CFG_DIR}/${DB_ARC_USER}.${TABLE_NAME}.sql  
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
    local DB_DB=$( x="${LOC^^}DB_DB"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)
            DB_SQL="SELECT column_name FROM information_schema.columns WHERE table_schema='${DB_DB}' and table_name='${TABLE_NAME}' order by ordinal_position;"
            ;;
        postgresql|sqlserver)
            DB_SQL="SELECT column_name FROM information_schema.columns WHERE table_catalog='${DB_DB}' and table_schema='${DB_SCHEMA}' and table_name='${TABLE_NAME}' order by ordinal_position;"
            ;;
        informix)
            DB_SQL="SELECT TRIM(c.colname) as column_name FROM informix.systables AS t JOIN informix.syscolumns AS c ON t.tabid = c.tabid WHERE t.owner='${DB_DB}' and t.tabname='${TABLE_NAME}' AND t.tabid >= 100 order by colno;"
            ;;
        *)
            echo "jdbc_cli: ${DB_GRP,,} needs to be handled."
            ;;
    esac

    # grab the column names
    if [ ! -z "$DB_SQL" ]; then
        echo "${DB_SQL}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v -e "^${REMOVE_COLS}" 
    fi
}


dump_table() {
    local LOC="${1:-SRC}"        # SRC|DST
    local TABLE_NAME="${2:-usertable}"    # usertable|sbtest1
    local col_names=${3:-$( list_columns $LOC $TABLE_NAME | paste -s -d, )}
    local REMOVE_COLS=${4:-ts2}

    # use parameter expansion https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    local DB_HOST=$( x="${LOC^^}DB_HOST"; echo ${!x} )
    local DB_PORT=$( x="${LOC^^}DB_PORT"; echo ${!x} )
    local DB_ARC_USER=$( x="${LOC^^}DB_ARC_USER"; echo ${!x} )
    local DB_ARC_PW=$( x="${LOC^^}DB_ARC_PW"; echo ${!x} )
    local DB_TYPE=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_GRP=$( x="${LOC^^}DB_GRP"; echo ${!x} )
    local DB_SCHEMA=$( x="${LOC^^}DB_SCHEMA"; echo ${!x} )
    local DB_JSQSH_DRIVER=$( x="${LOC^^}DB_JSQSH_DRIVER"; echo ${!x} )
    local DB_DB=$( x="${LOC^^}DB_DB"; echo ${!x} )

    case ${DB_GRP,,} in
        mysql)            
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_schema='${DB_DB}' AND Col.table_name='${TABLE_NAME}' order by Col.Column_Name;"
            ;;
        postgresql|sqlserver)            
            col_pk_sql="SELECT Col.Column_Name from INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, INFORMATION_SCHEMA.key_column_usage Col WHERE Col.Constraint_Name = Tab.Constraint_Name AND Tab.Constraint_Type = 'PRIMARY KEY' AND Col.Table_Name = Tab.Table_Name AND Col.table_catalog='${DB_DB}' AND Col.table_schema='${DB_SCHEMA}' AND Col.table_name='${TABLE_NAME}' order by Col.Column_Name;"
            ;;
        informix)      
            local parts=$( seq 1 1 16 | xargs -I % echo part% | paste -s -d, )
            local pk_col_ids_sql="select $parts from sysconstraints sc, sysindexes si, systables st where sc.tabid = si.tabid and si.tabid=st.tabid and st.tabname='${TABLE_NAME}' and st.owner='${DB_DB}' and si.tabid >= 100"  
            # DEBUG echo "${pk_col_ids_sql}"
            local pk_col_ids=$( echo "${pk_col_ids_sql}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v -e "${REMOVE_COLS}" | paste -s -d, )

            if [ -z "$pk_col_ids" ]; then
                col_pk_sql=""
            else                
                col_pk_sql="select c.colname from syscolumns c, systables t where c.tabid=t.tabid and c.colno in ($pk_col_ids) and t.tabname='${TABLE_NAME}' and t.owner='${DB_DB}' and t.tabid >= 100 order by c.colname" 
            fi
            ;;
        *)
            echo "$0: ${DB_TYPE,,} needs to be handled."
            ;;
    esac

    # DEBUG: echo "pksql: $col_pk_sql"
    if [ -z "${col_pk_sql}" ]; then 
        col_names_pk=""
    else
        col_names_pk=$( echo "${col_pk_sql}; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | grep -v -e "${REMOVE_COLS}" | paste -s -d, )
    fi
    # DEBUG:
    echo "pk cols: $col_names_pk"
    
    # if there is no primary key, then just sort by all of the columns
    if [ -z "${col_names_pk}" ]; then 
        # show the column names to be validated
        echo "${LOC} select ${col_names} from $TABLE_NAME;"        
        # dump the table in CSV
        echo "select ${col_names} from $TABLE_NAME; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" | sort > ${CFG_DIR}/${DB_DB}.${TABLE_NAME}.tsv 
    else 
        # show the column names to be validated
        col_names_pk="order by ${col_names_pk}"
        echo "${LOC} select ${col_names} from $TABLE_NAME $col_names_pk;"        
        # dump the table in CSV
        echo "select ${col_names} from $TABLE_NAME $col_names_pk; -m csv" | jdbc_cli_${LOC,,} "$JSQSH_CSV" > ${CFG_DIR}/${DB_DB}.${TABLE_NAME}.tsv 
    fi
    echo "${CFG_DIR}/${DB_DB}.${TABLE_NAME}.tsv" >&2 
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