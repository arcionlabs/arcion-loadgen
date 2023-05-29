#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh
. ${SCRIPTS_DIR}/lib/ycsb_jdbc_create_table.sh

[ -z "${YCSB_JDBC}" ] && YCSB_JDBC=/opt/ycsb/ycsb-jdbc-binding-0.18.0-SNAPSHOT

# defaults for the command line
export default_ycsb_rate=1
export default_ycsb_threads=1
export default_ycsb_timer=600
export default_ycsb_size_factor=1
export default_ycsb_table="THEUSERTABLE"  # YCSB default=usertable
export default_ycsb_fieldcount=10         # YCSB default
export default_ycsb_fieldlength=100       # YCSB default
export default_ycsb_batchsize=1024        

# set defaults
[ -z "${ycsb_rate}" ]        && export ycsb_rate=${default_ycsb_rate}
[ -z "${ycsb_threads}" ]     && export ycsb_threads=${default_ycsb_threads}
[ -z "${ycsb_timer}" ]       && export ycsb_timer=${default_ycsb_timer}
[ -z "${ycsb_size_factor}" ] && export ycsb_size_factor=${default_ycsb_size_factor}
[ -z "${ycsb_batchsize}" ]   && export ycsb_batchsize=${default_ycsb_batchsize}

# constants
export const_ycsb_insertstart=0
export const_ycsb_recordcount=100000
export const_ycsb_operationcount=1000000000
export const_ycsb_zeropadding=11
export const_ycsb_ycsbkeyprefix=0

ycsb_usage() {
  echo "ycsb: override on the command line or set
    -B ycsb_batchsize=${default_ycsb_batchsize}
    -r ycsb_rate=${default_ycsb_rate}
    -s ycsb_size_factor=${default_ycsb_size_factor}
    -t ycsb_threads=${default_ycsb_threads}
    -w ycsb_timer=${default_ycsb_timer}
  "
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function ycsb_opts() {
  local param
  local -i params_processed=0
  while [[ $# -gt 0 ]]; do
    # stop if on positional (first char without leading -) 
    [ "${1:0:1}" != '-' ] && break
    # stop on --
    [ "${1}" = '--' ] && break

    # process parameter
    param="$1"
    shift
    ((params_processed++))
    case $param in
      -h) 
        ycsb_usage 
        ;;
      -B|--batchsize) 
        args_ycsb_batchsize="$1"; shift; ((params_processed++))
        ;;
      -r) 
        args_ycsb_rate="$1"; shift; ((params_processed++))
        ;;
      -s) 
        args_ycsb_size_factor="$1"; shift; ((params_processed++))
        ;;
      -t) 
        args_ycsb_threads="$1"; shift; ((params_processed++))
        ;;
      -w) 
        args_ycsb_timer="$1"; shift; ((params_processed++))
        ;;
      *) 
        echo "ignoring $param" 
        ;;
    esac
  done
  
  # NOTE: too many threads will generate error from YCSB
  [ "$args_ycsb_threads" = "0" ] && 
    args_ycsb_threads=$(getconf _NPROCESSORS_ONLN)

  (( DEBUG >= 2 )) && {
    cat >&2 <<EOF 
      ycsb_opts: 
      args_ycsb_batchsize="$args_ycsb_batchsize"
      args_ycsb_rate="$args_ycsb_rate"
      args_ycsb_size_factor="$args_ycsb_size_factor"
      args_ycsb_timer="$args_ycsb_timer" 
      args_ycsb_threads="$args_ycsb_threads" 
      echo $*
EOF
  }
}

ycsb_rows() {
  local LOC="${1:-src}"        # SRC|DST 
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  x=$( echo "select max(ycsb_key) from ${ycsb_table}; -m csv" | jdbc_cli "${LOC,,}" "-n -v headers=false -v footers=false" )
  if [ -z "$x" ]; then
    echo "0"
  else  
    echo "$x" | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

ycsb_select_key() {
  local LOC="${1:-src}"        # SRC|DST 
  local ycsb_key="$2"
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  echo "select ycsb_key from ${ycsb_table} where ycsb_key=$ycsb_key; -m csv" | jdbc_cli ${LOC,,} "-n -v headers=false -v footers=false"
}


# set env vars used from src/dst
ycsb_src_dst_param() {
  local LOC="${1:-SRC}"
  db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  db_type=$( x="${LOC^^}DB_TYPE"; echo "${!x}" )
  jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
  jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
  jdbc_classpath=$( x="${LOC^^}DB_CLASSPATH"; echo "${!x}" )

  ycsb_rate=${args_ycsb_rate:-${workload_rate:-${default_ycsb_rate}}}
  ycsb_threads=${args_ycsb_threads:-${workload_threads:-${default_ycsb_threads}}}
  ycsb_timer=${args_ycsb_timer:-${workload_timer:-${default_ycsb_timer}}}
  ycsb_size_factor=${args_ycsb_size_factor:-${workload_size_factor:-${default_ycsb_size_factor}}}
  ycsb_batchsize=${args_ycsb_batchsize:-${workload_batchsize:-${default_ycsb_batchsize}}}
}

# calling sequences:
# ycsb_laod_src | ycsb_load_dst
#   ycsb_load_sf
#     ycsb_load

ycsb_load() {
  local jdbc_url=${1}
  local recordcount=${2}    

  # not override from command line args
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  if [ -z "${jdbc_url}" ] || [ -z "${recordcount}" ]; then echo "Error: jdbc_url and recordcount not set." >&2; return 1; fi

  local ycsb_load_basedon_sf=$( echo "scale=0; (l (${ycsb_size_factor}) ) / 1" | bc -l )
  if [ -z "${ycsb_load_basedon_sf}" ] || [ "${ycsb_load_basedon_sf}" = "0" ]; then
    ycsb_load_basedon_sf=1
  fi

  if (( ycsb_load_basedon_sf > ycsb_threads )); then
    echo "YCSB: auto setting load thread count to $ycsb_load_basedon_sf"
    ycsb_threads=${ycsb_load_basedon_sf}
  fi 

  # want multirow inserts for supported DBs
  case "${db_grp,,}" in
    oracle)
      JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false"
      ;;
    mysql)
      local jdbc_url="${jdbc_url}&rewriteBatchedStatements=true"
      ;;
    postgresql)
      local jdbc_url="${jdbc_url}&reWriteBatchedInserts=true"
      ;;
    # needs 0.18
    # sqlserver)
    #  jdbc_url="${jdbc_url}:IFX_USEPUT=1;"
    #  ;;
    # Does not improve perforamnce when autocommit=false
    # sqlserver)
    #  jdbc_url="${jdbc_url};useBulkCopyForBatchInsert=true"
    #  ;;
  esac 

  jdbc_classpath="${jdbc_classpath}" \
  JAVA_OPTS="${JAVA_OPTS}" \
  ${YCSB_JDBC}/bin/ycsb.sh load jdbc \
    -s \
    -threads ${ycsb_threads} \
    -p workload=site.ycsb.workloads.CoreWorkload \
    -p db.driver="${jdbc_driver}" \
    -p db.url="${jdbc_url}" \
    -p db.user="${db_user}" \
    -p db.passwd="${db_pw}" \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=false \
    -p jdbc.batchupdateapi=true \
    -p db.urlsharddelim='___' \
    -p db.batchsize=${ycsb_batchsize} \
    -p table=${ycsb_table} \
    -p insertstart=${ycsb_insertstart} \
    -p recordcount=${recordcount} \
    -p requestdistribution=uniform \
    -p zeropadding=${const_ycsb_zeropadding} \
    -p jdbc.ycsbkeyprefix=false \
    -p insertorder=ordered
}

# $1 = src|dst
# $2 = list of tables in the database
ycsb_load_sf() {
  local LOC="${1:-SRC}"        # SRC|DST

  # these should be set without defaults
  [ -z "${db_user}" ] && { echo "db_user not set" >&2; return 1; }
  [ -z "${db_pw}" ] && { echo "db_pw not set" >&2; return 1; }
  [ -z "${db_grp}" ] && { echo "db_grp not set" >&2; return 1; }
  [ -z "${jdbc_url}" ] && { echo "jdbc_url not set" >&2; return 1; }
  [ -z "${jdbc_driver}" ] && { echo "jdbc_driver not set" >&2; return 1; }
  [ -z "${jdbc_classpath}" ] && { echo "jdbc_classpath not set" >&2; return 1; }

  # list of tables in the databaes
  if [ -z "${2}" ]; then
    echo "ycsb_load_sf: retrieving the tables"
    declare -A "ycsb_load_sf_db_tabs=( $( list_tables "${LOC,,}" | awk -F, '/^table/ {print "[" $2 "]=" $2}' ) )"
  else
    echo "ycsb_load_sf: list of tables $2"
    local -n ycsb_load_sf_db_tabs=${2}
  fi

  # create table def if not found
  echo "${ycsb_load_sf_db_tabs[*]}"
  if [ -z "${ycsb_load_sf_db_tabs[theusertable]}" ]; then 
    echo "theusertable not found.  creating"
    ycsb_create_table | jdbc_cli "$LOC"
  fi

  # number of new records to add
  local ycsb_size_factor=${args_ycsb_size_factor:-${ycsb_size_factor:-${default_ycsb_size_factor}}}
  local ycsb_insertstart=$(ycsb_rows "$LOC")
  local ycsb_insertend=$((ycsb_size_factor * const_ycsb_recordcount))
  local ycsb_recordcount=$((ycsb_insertend - ycsb_insertstart))

  echo args_ycsb_size_factor=$args_ycsb_size_factor
  echo ycsb_size_factor=$ycsb_size_factor

  echo "YCSB: insert from $ycsb_insertstart to $ycsb_insertend ($ycsb_recordcount)"
  if (( ycsb_recordcount > 0 )); then
    ycsb_load ${jdbc_url} ${ycsb_recordcount}
  else
    echo "YCSB: skipping"
  fi
}

function ycsb_load_src() { 
  ycsb_src_dst_param "src"
  ycsb_opts "$@"
  ycsb_load_sf src
}

function ycsb_load_dst() { 
  ycsb_src_dst_param "dst"
  ycsb_opts "$@"
  ycsb_load_sf dst
}


ycsb_run() {
  # these should be set without defaults
  [ -z "${db_user}" ] && { echo "db_user not set" >&2; return 1; }
  [ -z "${db_pw}" ] && { echo "db_pw not set" >&2; return 1; }
  [ -z "${db_grp}" ] && { echo "db_grp not set" >&2; return 1; }
  [ -z "${jdbc_url}" ] && { echo "jdbc_url not set" >&2; return 1; }
  [ -z "${jdbc_driver}" ] && { echo "jdbc_driver not set" >&2; return 1; }
  [ -z "${jdbc_classpath}" ] && { echo "jdbc_classpath not set" >&2; return 1; }

  # not override from command line args
  local ycsb_table=${ycsb_table:-${default_ycsb_table}}

  # these not typically set
  local ycsb_insertstart=${ycsb_insertstart:-${const_ycsb_insertstart}}

  # start of logic
  local ycsb_recordcount=$(( $(ycsb_rows $LOC) ))

  case "${db_grp,,}" in
    oracle)
      # oracle 11gr2 required
      JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false"
      ;;
  esac 

  jdbc_classpath="${jdbc_classpath}" \
  JAVA_OPTS="${JAVA_OPTS}" \
  ${YCSB_JDBC}/bin/ycsb.sh run jdbc \
  -s \
  -threads ${ycsb_threads} \
  -target ${ycsb_rate} \
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
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p jdbc.batchupdateapi=true \
  -p db.batchsize=${ycsb_batchsize} \
  -p jdbc.autocommit=true \
  -p db.urlsharddelim='___' \
  -p requestdistribution=uniform \
  -p zeropadding=${const_ycsb_zeropadding} \
  -p jdbc.ycsbkeyprefix=false \
  -p insertorder=ordered &

  # save the PID  
  export YCSB_RUN_PID="$!"
  # wait for job to finish, expire, or killed by ctl-c
  trap kill_jobs SIGINT
  echo "ycsb waiting ${ycsb_timer}"
  wait_jobs "${ycsb_timer}"
  echo "ycsb waiting ${ycsb_timer} done"
  kill_jobs
}

function ycsb_run_src() {
  ycsb_src_dst_param "src"
  ycsb_opts "$@"
  ycsb_run "src" 
}

function ycsb_run_dst() {
  ycsb_src_dst_param "dst"
  ycsb_opts "$@"
  ycsb_run "dst"
}