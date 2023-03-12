#!/usr/bin/env bash

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

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

# finally, run with lowercase SRCDB_TYPE
case ${SRCDB_GRP,,} in
    mysql)
        echo ${SRCDB_HOST} ${SRCDB_GRP}
        sysbench oltp_read_write \
        --rand-type=uniform \
        --rate=${workload_rate} \
        --report-interval=10 \
        --mysql-host=${SRCDB_HOST} \
        --auto_inc=off \
        --db-driver=mysql \
        --mysql-user=${SRCDB_ARC_USER} \
        --mysql-password=${SRCDB_ARC_PW} \
        --mysql-db=${SRCDB_ARC_USER} \
        --mysql-port=${SRCDB_PORT} \
        --time=${workload_timer} \
        --threads=${workload_threads} \
        --tables=${workload_size_factor} \
        run
    ;;
    postgresql)
        echo ${SRCDB_HOST} ${SRCDB_GRP}
        sysbench oltp_read_write \
        --rand-type=uniform \
        --rate=${workload_rate} \
        --report-interval=10 \
        --pgsql-host=${SRCDB_HOST} \
        --auto_inc=off \
        --db-driver=pgsql \
        --pgsql-user=${SRCDB_ARC_USER} \
        --pgsql-password=${SRCDB_ARC_PW} \
        --pgsql-db=${SRCDB_ARC_USER} \
        --pgsql-port=${SRCDB_PORT} \
        --time=${workload_timer} \
        --threads=${workload_threads} \
        --tables=${workload_size_factor} \
    run
        ;;
    *)
        echo "Error: ${SRCDB_GRP} needs to be supproted"
        ;;
esac