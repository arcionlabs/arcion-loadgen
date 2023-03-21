#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions

ping_db () {
  local db_url=$1
  local db_port=$2
arcion@3bf3c122adc3:/scripts$ nmap -p 1521 -oG - oracle
# Nmap 7.80 scan initiated Mon Mar 20 20:02:10 2023 as: nmap -p 1521 -oG - oracle
Host: 172.19.0.2 (oracle.arcnet)        Status: Up
Host: 172.19.0.2 (oracle.arcnet)        Ports: 1521/open/tcp//oracle///
# Nmap done at Mon Mar 20 20:02:10 2023 -- 1 IP address (1 host up) scanned in 0.04 seconds
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

ping_db $DSTDB_HOST $DSTDB_PORT