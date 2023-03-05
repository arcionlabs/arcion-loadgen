#!/usr/bin/env bash

# not used.  deprecate

# these are read in by scripts at the start

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
SRCDB_TYPE=${SRCDB_TYPE:-mysql}
SRCDB_HOST=${SRCDB_HOST:-mysql-db}
DSTDB_TYPE=${DSTDB_TYPE:-mysql}
DSTDB_HOST=${DSTDB_HOST:-mysql-db-2}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

PG_ROOT_USER=${PG_ROOT_USER:-postgres}
PG_ROOT_PW=${PG_ROOT_PW:-password}

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}