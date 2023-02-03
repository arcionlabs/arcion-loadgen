#!/usr/bin/env bash

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/ini_jdbc.sh

col_name_sql="SELECT column_name FROM information_schema.columns WHERE table_name='sbtest1' order by ordinal_position;"

col_pk_sql="SELECT column_name FROM information_schema.key_column_usage WHERE constraint_name='primary' and table_name='sbtest1' order by ordinal_position;"

#echo $col_name_sql | mysql --skip_column_names -hmysql -uarc -ppassword -Darc | paste -s -d,

#echo $col_name_sql | psql --csv -t postgresql://arc:password@postgresql/arc | paste -s -d,

dump_db() {
    local DB_TYPE=$1
    local DB_ARC_USER=$2
    local DB_ARC_PW=$3
    local DB_HOST=$4
    local TABLE_NAME=$5
    local REMOVE_COLS=${6:-ts}

    col_name_sql="SELECT column_name FROM information_schema.columns WHERE table_schema='${DB_ARC_USER}' and table_name='${TABLE_NAME}' order by ordinal_position;"
    col_pk_sql="SELECT column_name FROM information_schema.key_column_usage WHERE constraint_name='primary' and table_schema='${DB_ARC_USER}' and table_name='${TABLE_NAME}' order by ordinal_position;"

case ${DB_TYPE,,} in
    mysql|mariadb|singlestore)
        col_names=$( echo ${col_name_sql} | mysql --skip_column_names -u${DB_ARC_USER} -p${DB_ARC_PW} -h${DB_HOST} -D${DB_ARC_USER} | grep -v ${REMOVE_COLS} | paste -s -d, )
        col_names_pk=$( echo ${col_pk_sql} | mysql --skip_column_names -u${DB_ARC_USER} -p${DB_ARC_PW} -h${DB_HOST} -D${DB_ARC_USER} | grep -v ${REMOVE_COLS} | paste -s -d, )

        echo cols=$col_names pk=$col_names_pk

        echo "select ${col_names} from ${TABLE_NAME} order by ${col_names_pk}" | mysql --skip_column_names -u${DB_ARC_USER} -p${DB_ARC_PW} -h${DB_HOST} -D${DB_ARC_USER} > ${CFG_DIR}/${DB_HOST}.${DB_ARC_USER}.${TABLE_NAME}.tsv

        echo ${CFG_DIR}/${DB_HOST}.${DB_ARC_USER}.${TABLE_NAME}.tsv
        ;;
    postgresql|cockroach)
        col_names=$( echo ${col_name_sql} | psql --csv -t postgresql://${DB_ARC_USER}:${DB_ARC_PW}@${DB_HOST}/${DB_ARC_USER} | paste -s -d, )
        col_names_pk=$( echo ${col_name_sql} | psql --csv -t postgresql://${DB_ARC_USER}:${DB_ARC_PW}@${DB_HOST}/${DB_ARC_USER} | paste -s -d, )

        echo "select ${col_names} from ${TABLE_NAME} order by ${col_names_pk}" | psql --csv -t postgresql://${DB_ARC_USER}:${DB_ARC_PW}@${DB_HOST}/${DB_ARC_USER} > ${CFG_DIR}/${DB_HOST}.${DB_ARC_USER}.${TABLE_NAME}.tsv

        echo ${CFG_DIR}/${DB_HOST}.${DB_ARC_USER}.${TABLE_NAME}.tsv
        ;;
    *)
        echo "$0: ${DB_TYPE,,} needs to be handled."
        ;;
esac
}

dump_db $SRCDB_TYPE $SRCDB_ARC_USER $SRCDB_ARC_PW $SRCDB_HOST sbtest1
dump_db $SRCDB_TYPE $SRCDB_ARC_USER $SRCDB_ARC_PW $SRCDB_HOST usertable
dump_db $DSTDB_TYPE $DSTDB_ARC_USER $DSTDB_ARC_PW $DSTDB_HOST sbtest1
dump_db $DSTDB_TYPE $DSTDB_ARC_USER $DSTDB_ARC_PW $DSTDB_HOST usertable

for TABLE_NAME in sbtest1 usertable; do
  ls ${CFG_DIR}/*.${TABLE_NAME}.tsv | xargs diff 
done

# for manual validation, 
# ls *usertable* | xargs diff
# ls *sbtest1* | xargs diff