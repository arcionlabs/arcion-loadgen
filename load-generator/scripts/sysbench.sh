#!/usr/bin/env bash

sysbench oltp_read_write \
--mysql-host=${MYSQL_HOST} \
--auto_inc=off --db-driver=mysql --mysql-user=sbt \
--mysql-password=password \
--mysql-db=sbt \
--report-interval=1 \
--time=60 \
--threads=1 \
run