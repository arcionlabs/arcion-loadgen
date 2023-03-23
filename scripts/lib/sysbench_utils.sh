#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/job_control.sh

# defaults for the command line
export default_sysbench_rate=1
export default_sysbench_threads=1
export default_sysbench_timer=600
export default_sysbench_size_factor=1
export default_sysbench_table="usertable"

# command line arguments
export sysbench_rate=${default_sysbench_rate}
export sysbench_threads=${default_sysbench_threads}
export sysbench_timer=${default_sysbench_timer}
export sysbench_size_factor=${default_sysbench_size_factor}

# constants
export const_sysbench_insertstart=0
export const_sysbench_recordcount=100000
export const_sysbench_operationcount=1000000000
export const_sysbench_zeropadding=11

sysbench_usage() {
  echo "sysbench: override on the command line or set
    -r sysbench_rate=${default_sysbench_rate}
    -t sysbench_threads=${default_sysbench_threads}
    -w sysbench_timer=${default_sysbench_timer}
    -s sysbench_size_factor=${default_sysbench_size_factor}
  "
}

function sysbench_opts() {
  # these are args that can be overridden from the command line
  # override from command line
  local opt
  while getopts ":hr:s:t:w:" opt; do
      case $opt in
          h ) sysbench_usage ;;
          r ) args_sysbench_rate="$OPTARG" ;;
          t ) args_sysbench_threads="$OPTARG" ;;
          w ) args_sysbench_timer="$OPTARG" ;;
          s ) args_sysbench_size_factor="$OPTARG" ;;
      esac
  done
  [ "$args_sysbench_threads" = "0" ] && args_sysbench_threads=$(getconf _NPROCESSORS_ONLN)
}

sysbench_rows_src() {
  local sysbench_table=${sysbench_table:-${default_sysbench_table}}

  x=$( echo "select max(sysbench_key) from ${sysbench_table}; -m csv" | jdbc_cli_src "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo $x | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

sysbench_rows_dst() {
  local sysbench_table=${sysbench_table:-${default_sysbench_table}}

  x=$( echo "select max(sysbench_key) from ${sysbench_table}; -m csv" | jdbc_cli_dst "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo $x | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

sysbench_select_key() {
  local sysbench_table=${sysbench_table:-${default_sysbench_table}}
  local sysbench_key="$1"

  echo "select sysbench_key from ${sysbench_table} where sysbench_key='$sysbench_key'; -m csv" | jdbc_cli "-n -v headers=false -v footers=false"
}

sysbench_load() {    
  local sysbench_threads=${sysbench_threads:-${default_sysbench_threads}}
  local sysbench_table=${sysbench_table:-${default_sysbench_table}}

if [[ ${sbtest1_cnt} == "0" ]]; then
  # on existing table, create new rows
  sysbench oltp_read_write --skip_table_create=on --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
elif [[ ${sbtest1_cnt} == "" ]]; then
  # create default table with new rows  
  sysbench oltp_read_write --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
else

  ${sysbench}/*jdbc*/bin/sysbench.sh load jdbc -s -threads ${sysbench_threads} \
    -p workload=site.sysbench.workloads.CoreWorkload \
    -p db.driver="${jdbc_driver}" \
    -p db.url="${jdbc_url}" \
    -p db.user=${db_user} \
    -p db.passwd=${db_pw} \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=true \
    -p jdbc.batchupdateapi=true \
    -p db.batchsize=1024  \
    -p table=${sysbench_table} \
    -p insertstart=${sysbench_insertstart} \
    -p recordcount=${const_sysbench_recordcount} \
    -p requestdistribution=uniform \
    -p zeropadding=${const_sysbench_zeropadding} \
    -p insertorder=ordered
}

sysbench_load_sf() {
  local sysbench_size_factor=${sysbench_size_factor:-${default_sysbench_size_factor}}
  local sysbench_insertstart=${sysbench_insertstart:-${const_sysbench_insertstart}}
  local sysbench_key 
  local key_found
  local i
  local sysbench_key_start=$(( $(sysbench_rows_src) / const_sysbench_recordcount ))

  echo "sysbench: starting from size factor $sysbench_key_start to ${sysbench_size_factor}"

  for i in $( seq ${sysbench_key_start} 1 $(( sysbench_size_factor-1 )) ); do 

    # sysbench key are padded 11 digits
    sysbench_key=$(printf user%0${const_sysbench_zeropadding}d ${sysbench_insertstart})

    # key already there? 
    echo -n "sysbench: Checking existance of sysbench_key ${sysbench_key}"
    key_found=$( sysbench_select_key $sysbench_key )

    # insert if not found
    if [ ! -z "${key_found}" ]; then 
      echo " not found.  start insert at ${sysbench_insertstart}"
      sysbench_load ${sysbench_insertstart}
    else
      echo " found.  skipping this factor"
    fi

    sysbench_insertstart=$(( sysbench_insertstart + const_sysbench_recordcount ))
  done
}

function sysbench_load_src() { 
  local db_host="${SRCDB_HOST}"  
  local db_port="${SRCDB_PORT}"  
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_grp=${SRCDB_GRP}
  local jdbc_url="${SRCDB_JDBC_URL}"
  local jdbc_driver="${SRCDB_JDBC_DRIVER}"

  local sysbench_size_factor=${workload_size_factor}

  sysbench_load_sf
}

function sysbench_load_dst() { 
  local db_host="${DSTDB_HOST}"  
  local db_port="${DSTDB_PORT}"  
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_grp=${DSTDB_GRP}
  local jdbc_url="${DSTDB_JDBC_URL}"
  local jdbc_driver="${DSTDB_JDBC_DRIVER}"
 
  local sysbench_size_factor=${workload_size_factor}

  sysbench_load_sf
}


sysbench_run() {
  local sysbench_rate=${sysbench_rate:-${default_sysbench_rate}}
  local sysbench_threads=${sysbench_threads:-${default_sysbench_threads}}
  local sysbench_timer=${sysbench_timer:-${default_sysbench_timer}}
  local sysbench_table=${sysbench_table:-${default_sysbench_table}}

  local sysbench_insertstart=${sysbench_insertstart:-${const_sysbench_insertstart}}

  ${sysbench}/*jdbc*/bin/sysbench.sh run jdbc -s -threads ${sysbench_threads} -target ${sysbench_rate} \
  -p updateproportion=1 \
  -p readproportion=0 \
  -p workload=site.sysbench.workloads.CoreWorkload \
  -p requestdistribution=uniform \
  -p table=${sysbench_table} \
  -p recordcount=${const_sysbench_recordcount} \
  -p insertstart=${sysbench_insertstart} \
  -p operationcount=${const_sysbench_operationcount} \
  -p db.driver=${jdbc_driver} \
  -p db.url="${jdbc_url}" \
  -p db.user=${db_user} \
  -p db.passwd="${db_pw}" \
  -p db.batchsize=1024  \
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p requestdistribution=uniform \
  -p zeropadding=11 \
  -p insertorder=ordered &    
  # save the PID  
  export sysbench_RUN_PID="$!"
  # wait for job to finish, expire, or killed by ctl-c
  trap kill_jobs SIGINT
  echo "sysbench waiting ${sysbench_timer}"
  wait_jobs "${sysbench_timer}"
  echo "sysbench waiting ${sysbench_timer} done"
  kill_jobs
}

function sysbench_run_src() {
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_grp=${SRCDB_GRP}
  local jdbc_url="${SRCDB_JDBC_URL}"
  local jdbc_driver="${SRCDB_JDBC_DRIVER}"
  local sysbench_recordcount=$(( $( sysbench_rows_src ) ))

  local sysbench_rate=${workload_rate}
  local sysbench_threads=${workload_threads}
  local sysbench_timer=${workload_timer}

  sysbench_run
}

function sysbench_run_dst() {
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_grp=${DSTDB_GRP}
  local jdbc_url="${DSTDB_JDBC_URL}"
  local jdbc_driver="${DSTDB_JDBC_DRIVER}"
  local sysbench_recordcount=$(( $(sysbench_rows_dst) ))

  local sysbench_rate=${workload_rate}
  local sysbench_threads=${workload_threads}
  local sysbench_timer=${workload_timer}
  
  sysbench_run
}