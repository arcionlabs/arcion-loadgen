#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh
. ${SCRIPTS_DIR}/lib/ycsb_globals.sh
. ${SCRIPTS_DIR}/lib/ycsb_args.sh
. ${SCRIPTS_DIR}/lib/ycsb_jdbc_create_table.sh

ycsb_rows() {
  local LOC="${1:-src}"        # SRC|DST 
  local sql="select max(ycsb_key) from ${ycsb_table}"

  if [ "${SRCDB_CASE}" = "upper" ]; then sql=$(echo $sql | tr '[:lower:]' '[:upper:]'); fi

  echo $sql >&2

  x=$( echo "$sql; -m csv" | jdbc_cli "${LOC,,}" "-n -v headers=false -v footers=false" | grep -v "^Connection property value")

  echo $x >&2

  if [ -z "$x" ]; then
    echo "0"
  else
    # remove user prefix exists  
    echo "$x" | sed 's/user//' | awk '{print int($1) + 1}'
  fi
}

ycsb_select_key() {
  local LOC="${1:-src}"        # SRC|DST 
  local ycsb_key="$2"
  local sql="select ycsb_key from ${ycsb_table} where ycsb_key=$ycsb_key"

  if [ ${SRCDB_CASE} = "upper" ]; then sql=$(echo $sql | tr '[:lower:]' '[:upper:]'); fi

  echo "$sql; -m csv" | jdbc_cli ${LOC,,} "-n -v headers=false -v footers=false"
}


# calling sequences:
# ycsb_laod_src | ycsb_load_dst
#   ycsb_load_sf
#     ycsb_load

ycsb_load() {
  local jdbc_url=${1}
  local recordcount=${2}    

  if [ -z "${jdbc_url}" ] || [ -z "${recordcount}" ]; then echo "Error: jdbc_url and recordcount not set." >&2; return 1; fi

  # set default if not set
  [ -z "${CFG_DIR}" ] && CFG_DIR=/tmp

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
    snowflake)
      local ycsb_batchsize=16384
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

  jdbc_url=$( echo $jdbc_url | sed "s/#_CHANGEME_#/${db_user}/g")

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
    -p fieldnameprefix="FIELD" \
    -p insertorder=ordered \
    -p fieldcount=0 2>&1 | tee $CFG_DIR/ycsb-load.log
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
    declare -A "ycsb_load_sf_db_tabs=( $( list_tables "${LOC,,}" | \
      awk -F',' '{print "[" $2 "]=" $2}' | tr '[:upper:]' '[:lower:]' ) )"
  else
    echo "ycsb_load_sf: list of tables $2"
    local -n ycsb_load_sf_db_tabs=${2}
  fi

  if [ -z "${ycsb_table}" ]; then exit 1; fi

  # create table def if not found
  # wahtis :$
  echo "looking for ${ycsb_table,,:$} in ${ycsb_load_sf_db_tabs[*]}"
  if [ -z "${ycsb_load_sf_db_tabs[${ycsb_table,,}]}" ]; then 
    echo "${ycsb_table} not found.  creating"
    ycsb_create_table ${ycsb_size_factor_name} | jdbc_cli "$LOC" "-n"
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
  ycsb_opts "$@"
  ycsb_src_dst_param "src"
  ycsb_load_sf src
}

function ycsb_load_dst() {   
  ycsb_opts "$@"
  ycsb_src_dst_param "dst"
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

  # set default if not set
  [ -z "${CFG_DIR}" ] && CFG_DIR=/tmp

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

  jdbc_url=$( echo $jdbc_url | sed "s/#_CHANGEME_#/${db_user}/g")

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
  -p fieldnameprefix="FIELD" \
  -p insertorder=ordered 2>&1 | tee $CFG_DIR/ycsb-run.log &

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
  ycsb_opts "$@"
  ycsb_src_dst_param "src"
  ycsb_run "src" 
}

function ycsb_run_dst() {
  ycsb_opts "$@"
  ycsb_src_dst_param "dst"
  ycsb_run "dst"
}