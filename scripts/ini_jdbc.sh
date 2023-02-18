#!/usr/bin/env bash

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

# standard source id / password 
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}
DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcsrc}
DSTDB_ARC_PW=${DSTDB_ARC_PW:-password}

case "${SRCDB_GRP,,}" in
  mariadb| mysql|singlestore)
    SRC_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    SRC_JDBC_URL="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme"
    ;;
  postgresql|cockroach)
    SRC_JDBC_DRIVER="org.postgresql.Driver"
    SRC_JDBC_URL="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    SRC_PG_URL="postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}"
    ;;
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support"
    ;;
esac

case "${DSTDB_GRP,,}" in
  mariadb| mysql|singlestore)
    DST_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    DST_JDBC_URL="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme"
    ;;
  postgresql|cockroach)
    DST_JDBC_DRIVER="org.postgresql.Driver"
    DST_JDBC_URL="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${ARCDST_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    DST_PG_URL="postgresql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}"
    ;; 
  *)
    echo "$0: DSTDB_GRP: ${DSTDB_GRP} need to code support"
    ;;
esac

export SRC_JDBC_DRIVER
export SRC_JDBC_URL
export SRC_PG_URL

export DST_JDBC_DRIVER
export DST_JDBC_URL
export DST_PG_URL