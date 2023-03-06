#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions

ping_db () {
  local db_url=$1
  local db_port=$2
  # arcion@d6b52ea6c1ae:/scripts$ nmap -p 29092 -oG - kafka/32
  # Nmap 7.80 scan initiated Wed Feb 22 13:31:03 2023 as: nmap -p 29092 -oG - kafka/32
  # Host: 172.18.0.12 (kafka.arcnet)        Status: Up
  # Host: 172.18.0.12 (kafka.arcnet)        Ports: 29092/open/tcp/////
  rc=1
  while [ ${rc} != 0 ]; do
    nmap -p ${db_port} -oG - ${db_url} | tee /tmp/nmap.$$
    grep "Ports: ${db_port}/open/tcp/////$" /tmp/nmap.$$ 
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${db_url} ${db_port} to connect"
      sleep 10
    fi
  done
}

ping_db $SRCDB_HOST $SRCDB_PORT