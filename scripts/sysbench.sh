#!/usr/bin/env bash

RATE=${1:-1}
THREADS=${1:-1}

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

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