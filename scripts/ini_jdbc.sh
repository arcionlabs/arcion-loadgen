#!/usr/bin/env bash

case "${SRCDB_TYPE,,}" in
  mysql)
    JDBC_DRIVER="org.mariadb.jdbc.Driver"
    JDBC_URL="jdbc:mariadb://${SRCDB_HOST}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    ;;
  postgres)
    JDBC_DRIVER="org.postgresql.Driver"
    JDBC_URL="jdbc:postgresql://${SRCDB_HOST}/${ARCSRC_USER}?"   
    ;;
  cockroach)
    JDBC_DRIVER="org.postgresql.Driver"
    JDBC_URL="jdbc:postgresql://${SRCDB_HOST}/${ARCSRC_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    ;; 
  *)
    echo "SRCDB_TYPE: ${SRCDB_TYPE} need to code support"
    ;;
esac

export JDBC_DRIVER
export JDBC_URL