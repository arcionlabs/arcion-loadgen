#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
. ${SCRIPTS_DIR}/lib/ping_utils.sh

# wait for host and port to be up
ping_host_port $DSTDB_HOST $DSTDB_PORT
