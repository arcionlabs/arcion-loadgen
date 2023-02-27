#!/usr/bin/env bash

case "${SRCDB_GRP,,}" in
  mysql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mysql"
    SRCDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    SRCDB_JDBC_URL="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    SRCDB_JDBC_URL_IDPW="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    ;;
  postgresql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="pgsql"
    SRCDB_JDBC_DRIVER="org.postgresql.Driver"
    SRCDB_JDBC_URL="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    SRCDB_JDBC_URL_IDPW="postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"
    ;;
  mongodb)
    SRCDB_YCSB_DRIVER="mongodb"
    SRCDB_JSQSH_DRIVER=""
    SRCDB_ROOT_URL="mongodb://${SRCDB_ROOT}:${SRCDB_PW}@${SRCDB_HOST}:${SRCDB_PORT}/"   
    SRCDB_JDBC_URL="mongodb://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?w=0"
    SRCDB_JDBC_URL_IDPW="mongodb://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?w=0"
    ;;
  sqlserver)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mssql2k5"
    SRCDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    SRCDB_JDBC_URL="jdbc:sqlserver://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true"   
    SRCDB_JDBC_URL_IDPW="sqlserver://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true"
    ;;         
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support"
    ;;
esac

case "${DSTDB_GRP,,}" in
  mysql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mysql"
    DSTDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    DSTDB_JDBC_URL="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    DSTDB_JDBC_URL_IDPW="jdbc:mysql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    ;;
  postgresql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="pgsql"
    DSTDB_JDBC_DRIVER="org.postgresql.Driver"
    DSTDB_JDBC_URL="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${ARCDST_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    DSTDB_JDBC_URL_IDPW="postgresql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"
    ;; 
  mongodb)
    DSTDB_YCSB_DRIVER="mongodb"
    DSTDB_JSQSH_DRIVER=""
    DSTDB_ROOT_URL="mongodb://${DSTDB_ROOT}:${DSTDB_PW}@${DSTDB_HOST}:${DSTDB_PORT}/"
    DSTDB_JDBC_URL="mongodb://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?w=0"
    DSTDB_JDBC_URL_IDPW="mongodb://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?w=0"
    ;;     
  sqlserver)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mssql2k5"
    DSTDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    DSTDB_JDBC_URL="jdbc:sqlserver://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?autoReconnect=true"   
    DSTDB_JDBC_URL_IDPW="sqlserver://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?autoReconnect=true"
    ;;     
  *)
    echo "$0: DSTDB_GRP: ${DSTDB_GRP} need to code support"
    ;;
esac

export SRCDB_JDBC_DRIVER
export SRCDB_JDBC_URL
export SRCDB_JDBC_URL_IDPW
export SRCDB_ROOT_URL

export DSTDB_JDBC_DRIVER
export DSTDB_JDBC_URL
export DSTDB_JDBC_URL_IDPW
export DSTDB_ROOT_URL

export SRCDB_YCSB_DRIVER
export DSTDB_YCSB_DRIVER
export SRCDB_JSQSH_DRIVER
export DSTDB_JSQSH_DRIVER