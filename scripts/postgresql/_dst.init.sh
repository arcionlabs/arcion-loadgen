#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

PG_ROOT_USER=${PG_ROOT_USER:-postgres}
PG_ROOT_PW=${PG_ROOT_PW:-password}

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}

# note the convention to save the output /tmp/arcion/${DSTDB_HOST}

if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql ]; then
    echo "Running root"
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql | psql postgresql://${PG_ROOT_USER}:${PG_ROOT_PW}@${DSTDB_HOST}/ 2>&1 | tee /tmp/arcion/${DSTDB_HOST}/dst.init.log
fi

# with the arcsrc user
if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcsrc.sql ]; then
    echo "Running arcsrc"
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcsrc.sql | psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${DSTDB_HOST}/ 2>&1 | tee /tmp/arcion/${DSTDB_HOST}/dst.init.arcsrc.log
fi