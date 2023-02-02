#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

CRL_ROOT_USER=${CRL_ROOT_USER:-root}
CRL_ROOT_PW=${CRL_ROOT_PW:-password}
CRL_PORT=26257

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}

# note the convention to save the output /tmp/arcion/${DSTDB_HOST}
export PGCLIENTENCODING='utf-8'
cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql | psql postgresql://${CRL_ROOT_USER}:${CRL_ROOT_PW}@${DSTDB_HOST}:${CRL_PORT}/defaultdb?sslmode=disable 2>&1 | tee /tmp/arcion/${DSTDB_HOST}/dst.init.log

