#!/usr/bin/env bash

# inputs
RATE=${1:-1}
THREADS=${2:-1}

# env
SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

# bail if sysbench is not installed
which sysbench > /dev/null 2>&1
if [ $? != "0" ]; then
    echo "Error: sysbench not found.  Try 'sudo apt-get install sysbench' or 'brew install sysbench'"
    exit 1
fi

# standard source id / password 
SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

# get the jdbc driver to match
. ${SCRIPTS_DIR}/ini_jdbc.sh
echo $JDBC_DRIVER
echo $JDBC_URL

# finally, run with lowercase SRCDB_TYPE
case ${SRCDB_TYPE,,} in
    mysql)
        echo ${SRCDB_HOST} ${SRCDB_TYPE}
        sysbench oltp_read_write \
        --rand-type=uniform \
        --rate=${RATE} \
        --report-interval=10 \
        --mysql-host=${SRCDB_HOST} \
        --auto_inc=off \
        --db-driver=mysql \
        --mysql-user=${SRCDB_ARC_USER} \
        --mysql-password=${SRCDB_ARC_PW} \
        --mysql-db=${SRCDB_ARC_USER} \
        --time=60 \
        --threads=${THREADS} \
        run
    ;;
    postgres)
        echo ${SRCDB_HOST} ${SRCDB_TYPE}
        sysbench oltp_read_write \
        --rand-type=uniform \
        --rate=${RATE} \
        --report-interval=10 \
        --pgsql-host=${SRCDB_HOST} \
        --auto_inc=off \
        --db-driver=pgsql \
        --pgsql-user=${SRCDB_ARC_USER} \
        --pgsql-password=${SRCDB_ARC_PW} \
        --pgsql-db=${SRCDB_ARC_USER} \
        --time=60 \
        --threads=${THREADS} \
        run
        ;;
    *)
        echo "Error: ${SRCDB_TYPE} needs to be supproted"
        ;;
esac