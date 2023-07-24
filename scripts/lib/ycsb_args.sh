#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/ycsb_globals.sh

ycsb_usage() {
  echo "ycsb: override on the command line or set
    -B|--batchsize ycsb_batchsize=${default_ycsb_batchsize}
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

# set env vars used from src/dst
ycsb_src_dst_param() {
  local LOC="${1:-SRC}"
  export db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  export db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  export db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  export db_type=$( x="${LOC^^}DB_TYPE"; echo "${!x}" )
  export db_case_senstivity=$( x="${LOC^^}DB_CASE_SENSTIVITY"; echo "${!x}" )
  export jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
  export jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
  export jdbc_classpath=$( x="${LOC^^}DB_CLASSPATH"; echo "${!x}" )

  export ycsb_rate=${args_ycsb_rate:-${workload_rate:-${default_ycsb_rate}}}
  export ycsb_threads=${args_ycsb_threads:-${workload_threads:-${default_ycsb_threads}}}
  export ycsb_timer=${args_ycsb_timer:-${workload_timer:-${default_ycsb_timer}}}
  export ycsb_size_factor=${args_ycsb_size_factor:-${workload_size_factor:-${default_ycsb_size_factor}}}
  export ycsb_batchsize=${args_ycsb_batchsize:-${workload_batchsize:-${default_ycsb_batchsize}}}

  export ycsb_table=${default_ycsb_table}
  case "${db_case_senstivity,,}" in
    upper)
      ycsb_table=${ycsb_table^^}
      ;;
    lower)
      ycsb_table=${ycsb_table,,}
      ;;
  esac

  export ycsb_size_factor_name
  if [[ "${ycsb_size_factor}" != "1" ]]; then 
    ycsb_table=${ycsb_table}${ycsb_size_factor}; 
    ycsb_size_factor_name=${ycsb_size_factor}
  fi
}

