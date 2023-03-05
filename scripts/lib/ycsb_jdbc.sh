#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh

# defaults for the command line
export default_ycsb_rate=1
export default_ycsb_threads=1
export default_ycsb_timer=600
export default_ycsb_size_factor=1
export default_ycsb_table="usertable"

# command line arguments
export ycsb_rate=${default_ycsb_rate}
export ycsb_threads=${default_ycsb_threads}
export ycsb_timer=${default_ycsb_timer}
export ycsb_size_factor=${default_ycsb_size_factor}

# constants
export const_ycsb_insertstart=0
export const_ycsb_recordcount=100000
export const_ycsb_operationcount=1000000000
export const_ycsb_zeropadding=11

ycsb_usage() {
  echo "ycsb: override on the command line or set
    -r ycsb_rate=${default_ycsb_rate}
    -t ycsb_threads=${default_ycsb_threads}
    -w ycsb_timer=${default_ycsb_timer}
    -s ycsb_size_factor=${default_ycsb_size_factor}
  "
}

function ycsb_opts() {
  # these are args that can be overridden from the command line
  # override from command line
  local opt
  while getopts ":hr:s:t:w:" opt; do
      case $opt in
          h ) ycsb_usage ;;
          r ) args_ycsb_rate="$OPTARG" ;;
          t ) args_ycsb_threads="$OPTARG" ;;
          w ) args_ycsb_timer="$OPTARG" ;;
          s ) args_ycsb_size_factor="$OPTARG" ;;
      esac
  done
  [ "$args_ycsb_threads" = "0" ] && args_ycsb_threads=$(getconf _NPROCESSORS_ONLN)
}

ycsb_rows_src() {
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  x=$( echo "select max(ycsb_key) from ${ycsb_table}; -m csv" | jdbc_cli_src "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo $x | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

ycsb_rows_dst() {
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  x=$( echo "select max(ycsb_key) from ${ycsb_table}; -m csv" | jdbc_cli_dst "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo $x | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

ycsb_select_key() {
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}
  local ycsb_key="$1"

  echo "select ycsb_key from ${ycsb_table} where ycsb_key='$ycsb_key'; -m csv" | jdbc_cli "-n -v headers=false -v footers=false"
}

ycsb_load() {    
  local ycsb_threads=${ycsb_threads:-${default_ycsb_threads}}
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  # want multirow inserts for supported DBs
  case "${db_grp,,}" in
    mysql)
      jdbc_url="${jdbc_url}&rewriteBatchedStatements=true"
      ;;
    postgresql)
      jdbc_url="${jdbc_url}&eWriteBatchedInserts=true"
    ;;
  esac 

  ${YCSB}/*jdbc*/bin/ycsb.sh load jdbc -s -threads ${ycsb_threads} \
    -p workload=site.ycsb.workloads.CoreWorkload \
    -p db.driver="${jdbc_driver}" \
    -p db.url="${jdbc_url}" \
    -p db.user=${db_user} \
    -p db.passwd=${db_pw} \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=true \
    -p jdbc.batchupdateapi=true \
    -p db.batchsize=1024  \
    -p table=${ycsb_table} \
    -p insertstart=${ycsb_insertstart} \
    -p recordcount=${const_ycsb_recordcount} \
    -p requestdistribution=uniform \
    -p zeropadding=${const_ycsb_zeropadding} \
    -p insertorder=ordered
}

ycsb_load_sf() {
  local ycsb_size_factor=${ycsb_size_factor:-${default_ycsb_size_factor}}
  local ycsb_insertstart=${ycsb_insertstart:-${const_ycsb_insertstart}}
  local ycsb_key 
  local key_found
  local i
  local ycsb_key_start=$(( $(ycsb_rows_src) / const_ycsb_recordcount ))

  echo "YCSB: starting from size factor $ycsb_key_start to ${ycsb_size_factor}"

  for i in $( seq ${ycsb_key_start} 1 $(( ycsb_size_factor-1 )) ); do 

    # ycsb key are padded 11 digits
    ycsb_key=$(printf user%0${const_ycsb_zeropadding}d ${ycsb_insertstart})

    # key already there? 
    echo -n "YCSB: Checking existance of ycsb_key ${ycsb_key}"
    key_found=$( ycsb_select_key $ycsb_key )

    # insert if not found
    if [ ! -z "${key_found}" ]; then 
      echo " not found.  start insert at ${ycsb_insertstart}"
      ycsb_load ${ycsb_insertstart}
    else
      echo " found.  skipping this factor"
    fi

    ycsb_insertstart=$(( ycsb_insertstart + const_ycsb_recordcount ))
  done
}

function ycsb_load_src() { 
  local db_host="${SRCDB_HOST}"  
  local db_port="${SRCDB_PORT}"  
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_grp=${SRCDB_GRP}
  local jdbc_url="${SRCDB_JDBC_URL}"
  local jdbc_driver="${SRCDB_JDBC_DRIVER}"

  local ycsb_size_factor=${workload_size_factor}

  ycsb_load_sf
}

function ycsb_load_dst() { 
  local db_host="${DSTDB_HOST}"  
  local db_port="${DSTDB_PORT}"  
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_grp=${DSTDB_GRP}
  local jdbc_url="${DSTDB_JDBC_URL}"
  local jdbc_driver="${DSTDB_JDBC_DRIVER}"
 
  local ycsb_size_factor=${workload_size_factor}

  ycsb_load_sf
}


ycsb_run() {
  local ycsb_rate=${ycsb_rate:-${default_ycsb_rate}}
  local ycsb_threads=${ycsb_threads:-${default_ycsb_threads}}
  local ycsb_timer=${ycsb_timer:-${default_ycsb_timer}}
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  local ycsb_insertstart=${ycsb_insertstart:-${const_ycsb_insertstart}}

  ${YCSB}/*jdbc*/bin/ycsb.sh run jdbc -s -threads ${ycsb_threads} -target ${ycsb_rate} \
  -p updateproportion=1 \
  -p readproportion=0 \
  -p workload=site.ycsb.workloads.CoreWorkload \
  -p requestdistribution=uniform \
  -p table=${ycsb_table} \
  -p recordcount=${const_ycsb_recordcount} \
  -p insertstart=${ycsb_insertstart} \
  -p operationcount=${const_ycsb_operationcount} \
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
  export YCSB_RUN_PID="$!"
  # wait 
  if (( ycsb_timer != 0 )); then
    echo "YCSB: will be killed in ${ycsb_timer} secs" >&2
    wait_jobs "$YCSB_RUN_PID" "${ycsb_timer}" "1"
  fi  
}

function ycsb_run_src() {
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_grp=${SRCDB_GRP}
  local jdbc_url="${SRCDB_JDBC_URL}"
  local jdbc_driver="${SRCDB_JDBC_DRIVER}"
  local ycsb_recordcount=$(( $( ycsb_rows_src ) ))

  local ycsb_rate=${workload_rate}
  local ycsb_threads=${workload_threads}
  local ycsb_timer=${workload_timer}

  ycsb_run
}

function ycsb_run_dst() {
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_grp=${DSTDB_GRP}
  local jdbc_url="${DSTDB_JDBC_URL}"
  local jdbc_driver="${DSTDB_JDBC_DRIVER}"
  local ycsb_recordcount=$(( $(ycsb_rows_dst) ))

  local ycsb_rate=${workload_rate}
  local ycsb_threads=${workload_threads}
  local ycsb_timer=${workload_timer}
  
  ycsb_run
}