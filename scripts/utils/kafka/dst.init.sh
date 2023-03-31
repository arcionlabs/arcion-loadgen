#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
. ${SCRIPTS_DIR}/lib/ping_utils.sh
. ${SCRIPTS_DIR}/lib/yaml_key_val.sh

# get the host and port from YAML
DB_HOST=$( yaml_key_val ${CFG_DIR}/dst.yaml host )
DB_PORT=$( yaml_key_val ${CFG_DIR}/dst.yaml port )

# wait for host and port to be up
ping_host_port $DB_HOST $DB_PORT
