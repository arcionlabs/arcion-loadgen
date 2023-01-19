#!/usr/bin/env bash

local THREADS=${1:-1}

sysbench oltp_read_write \
--mysql-host=${SRCDB_HOST} \
--auto_inc=off --db-driver=mysql --mysql-user=arcion \
--mysql-password=password \
--mysql-db=arcion \
--report-interval=1 \
--time=60 \
--threads=${THREADS} \
run