#!/usr/bin/env bash

# confirm DB is up and can return list of databases
# mysql container during the startup how up as up, but is not responding 
ping_db () {
  declare -n PINGDB=$1
  shift

  local HOST=$1
  local PORT=$2
  local JSQSH_DRIVER=$3 
  local USER=$4
  local PW=$5

  rc=1
  while [ ${rc} != 0 ]; do
    # NOTE: the quote is required to create the hash correctly
    out=( $( echo '\databases' | jsqsh --driver="${JSQSH_DRIVER}" --user="${USER}" --password="${PW}" --server="${HOST}" --port="${PORT}" | awk -F'|' 'NF>1 {print $2}' | tr -d ' ') )
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${JSQSH_DRIVER}://${USER}@${HOST}:${PORT} to connect"
      sleep 10
    fi
    for db in ${out[*]}; do
      PINGDB[${db}]="${db}"
    done
  done
}

# verify host is up
ping_host () {
  local db_url=$1
  # arcion@d6b52ea6c1ae:/scripts$ nmap -p 29092 -oG - kafka/32
  # Nmap 7.80 scan initiated Wed Feb 22 13:31:03 2023 as: nmap -p 29092 -oG - kafka/32
  # Host: 172.18.0.12 (kafka.arcnet)        Status: Up
  # Host: 172.18.0.12 (kafka.arcnet)        Ports: 29092/open/tcp/////
  rc=1
  while [ ${rc} != 0 ]; do
    nmap -sn -oG - ${db_url} | tee /tmp/nmap.$$
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${db_url} to connect"
      sleep 10
    fi
  done
}

# verify host is up and port is up as well
ping_host_port () {
  local db_url=$1
  local db_port=$2
  # arcion@d6b52ea6c1ae:/scripts$ nmap -p 29092 -oG - kafka/32
  # Nmap 7.80 scan initiated Wed Feb 22 13:31:03 2023 as: nmap -p 29092 -oG - kafka/32
  # Host: 172.18.0.12 (kafka.arcnet)        Status: Up
  # Host: 172.18.0.12 (kafka.arcnet)        Ports: 29092/open/tcp/////
  rc=1
  while [ ${rc} != 0 ]; do
    nmap -p ${db_port} -oG - ${db_url} | tee /tmp/nmap.$$
    grep "Ports: ${db_port}/open/" /tmp/nmap.$$ 
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${db_url}:${db_port} to connect"
      sleep 10
    fi
  done
}