#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/jdbc_cli.sh

# confirm DB is up and can return list of databases
# mysql container during the startup how up as up, but is not responding 
ping_db () {
  if [ -z "${1}" ]; then echo "ping_db: \$1 not specified. declare -A dbsfound; ping_db dbsfound"; return 1; fi

  declare -n PINGDB=$1
  local LOC=${2:-SRC}
  local max_retries=${3:-3}
  local retry_count=0
  local rc

  local db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
  local db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" )

  rc=1
  while [ ${rc} != 0 ]; do
    list_dbs $LOC >/tmp/ping_utils.out.$$ 2>/tmp/ping_utils.err.$$ 
    rc=${?} # want jsqsh rc code
    # DEBUG echo "x${?}x"
    # DEBUG cat /tmp/ping_utils.out.$$ 
    # DEBUG cat /tmp/ping_utils.err.$$ 
    if [ "${rc}" == 0 ]; then break; fi

    cat /tmp/ping_utils.err.$$
    # if host is down, then don't wait
    if [ -n "$( grep \
      -e 'Socket fail to connect' \
      -e 'The connection attempt failed' \
      -e 'Verify the connection properties' \
      -e 'Connection string is invalid. Unable to parse.' \
      /tmp/ping_utils.err.$$ )" ]; then
        break  
    fi

    # stop on max retries
    (( retry_count++ ))
    if (( max_retries > 0 )) && (( retry_count >= max_retries )); then
      break
    fi

    # wait
    echo "ping_db: $retry_count/$max_retries waiting 10 sec for ${db_url} to connect"
    sleep 10    
  done

  # lower case the db names
  if [ ${rc} == 0 ]; then
    for line in $( cat /tmp/ping_utils.out.$$ ); do
      db="$(echo $line | awk -F, '{print $1}')"
      count="$(echo $line | awk -F, '{print $2}')"
      PINGDB["${db,,}"]="${count}"
    done
  fi

  rm /tmp/ping_utils.out.$$
  rm /tmp/ping_utils.err.$$
  return $rc
}

# verify host is up
ping_host () {
  local db_url=${1}
  local max_retries=${2:-10}

  [ -z "$db_url" ] && { echo "ping_host: \$1 must be host"; return 1; }

  db_urlnew=$(echo $db_url | sed -e 's|^[^/]*//||' -e 's|^.*@||' -e 's|/.*$||' -e 's|\:.*$||')
  if [ "${db_urlnew}" != "${db_url}" ]; then 
    echo "hostname for ping is $db_urlnew"
    db_url=$db_urlnew 
  fi

  # arcion@d6b52ea6c1ae:/scripts$ nmap -p 29092 -oG - kafka/32
  # Nmap 7.80 scan initiated Wed Feb 22 13:31:03 2023 as: nmap -p 29092 -oG - kafka/32
  # Host: 172.18.0.12 (kafka.arcnet)        Status: Up
  # Host: 172.18.0.12 (kafka.arcnet)        Ports: 29092/open/tcp/////
  local rc=1
  local retry_count=0
  while [ ${rc} != 0 ]; do
    # -sn no port scan
    # "-oG -" grep friendly to stdout
    nmap -sn -oG - ${db_url} | tee /tmp/nmap.$$
    grep "1 host up" /tmp/nmap.$$ 
    rc=${?}
    if [ ${rc} == 0 ]; then
      break
    fi

    # stop on max retries
    (( retry_count++ ))
    if (( max_retries > 0 )) && (( retry_count >= max_retries )); then
      break
    fi

    # wait
    echo "ping_host: $retry_count/$max_retries waiting 10 sec for ${db_url} to connect"
    sleep 10
  done

  return ${rc}
}

# verify host is up and port is up as well
ping_host_port () {
  local db_url=$1
  local db_port=$2
  local max_retries=${3:-10}
  # arcion@d6b52ea6c1ae:/scripts$ nmap -p 29092 -oG - kafka/32
  # Nmap 7.80 scan initiated Wed Feb 22 13:31:03 2023 as: nmap -p 29092 -oG - kafka/32
  # Host: 172.18.0.12 (kafka.arcnet)        Status: Up
  # Host: 172.18.0.12 (kafka.arcnet)        Ports: 29092/open/tcp/////
  local rc=1
  local retry_count=0

  [ -z "$db_url" ] && { echo "ping_host_port: \$1 must be host"; return 1; }
  [ -z "$db_port" ] && { echo "ping_host_port: \$2 must be port"; return 1; }

  db_urlnew=$(echo $db_url | sed -e 's|^[^/]*//||' -e 's|^.*@||' -e 's|/.*$||' -e 's|\:.*$||')
  if [ "${db_urlnew}" != "${db_url}" ]; then 
    echo "hostname for ping is $db_urlnew"
    db_url=$db_urlnew 
  fi

  while [ ${rc} != 0 ]; do
    nmap -p ${db_port} -oG - ${db_url} | tee /tmp/nmap.$$
    grep "Ports: ${db_port}/open/" /tmp/nmap.$$ 
    rc=${?}
    if [ ${rc} == 0 ]; then
      break
    fi

    # stop on max retries
    (( retry_count++ ))
    if (( max_retries > 0 )) && (( retry_count >= max_retries )); then
      break
    fi

    # wait
    echo "ping_host_port: $retry_count/$max_retries waiting 10 sec for ${db_url} to connect"
    sleep 10
  done

  return ${rc}
}