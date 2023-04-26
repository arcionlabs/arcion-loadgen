#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# get the host and port from YAML
DB_HOST=$( yaml_key_val ${CFG_DIR}/src.yaml host )
DB_PORT=$( yaml_key_val ${CFG_DIR}/src.yaml port )

# wait for host and port to be up
ping_host_port $DB_HOST $DB_PORT