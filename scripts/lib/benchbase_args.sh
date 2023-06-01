#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/benchbase_globals.sh

bb_usage() {
  echo "benchbase: override on the command line or set
    -B|--batchsize=${default_bb_batchsize}
    -L|--loc=${default_bb_loc}
    -M|--modules=${default_bb_modules_csv}
    -r bb_rate=${default_bb_rate}
    -s bb_size_factor=${default_bb_size_factor}
    -t bb_threads=${default_bb_threads}
    -w bb_timer=${default_bb_timer}
  "
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function bb_opts() {
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
        bb_usage 
        ;;
      -B|--batchsize) 
        args_bb_batchsize="$1"; shift; ((params_processed++))
        ;;
      -L|--loc) 
        args_bb_loc="$1"; shift; ((params_processed++))
        ;;        
      -M|--modules) 
        args_bb_modules_csv="$1"; shift; ((params_processed++))
        ;;
      -r) 
        args_bb_rate="$1"; shift; ((params_processed++))
        ;;
      -s) 
        args_bb_size_factor="$1"; shift; ((params_processed++))
        ;;
      -t) 
        args_bb_threads="$1"; shift; ((params_processed++))
        ;;
      -w) 
        args_bb_timer="$1"; shift; ((params_processed++))
        ;;
      *) 
        echo "ignoring $param" 
        ;;
    esac
  done
  
  # NOTE: too many threads will generate error from YCSB
  [ "$args_bb_threads" = "0" ] && 
    args_bb_threads=$(getconf _NPROCESSORS_ONLN)

  (( DEBUG >= 2 )) && {
    cat >&2 <<EOF 
      bb_opts: 
      args_bb_batchsize="$args_bb_batchsize"
      args_bb_rate="$args_bb_rate"
      args_bb_size_factor="$args_bb_size_factor"
      args_bb_timer="$args_bb_timer" 
      args_bb_threads="$args_bb_threads" 
      echo $*
EOF
  }
}

# set env vars used from src/dst
bb_src_dst_param() {
  local LOC="${1:-SRC}"
  export db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
  export db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
  export db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
  export db_type=$( x="${LOC^^}DB_TYPE"; echo "${!x}" )
  export jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
  export jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
  export jdbc_classpath=$( x="${LOC^^}DB_CLASSPATH"; echo "${!x}" )
  export db_benchbase_type=$( x="${LOC^^}DB_BENCHBASE_TYPE"; echo "${!x}" )
  export db_jdbc_no_rewrite=$( x="${LOC^^}DB_JDBC_NO_REWRITE"; echo "${!x}" )

  export bb_loc=${args_bb_loc:-SRC}
  export bb_modules_csv=${args_bb_modules_csv:-${workload_modules_bb:-${default_bb_modules_csv}}}
  export bb_rate=${args_bb_rate:-${workload_rate_bb:-${default_bb_rate}}}
  export bb_timer=${args_bb_timer:-${workload_timer_bb:-${default_bb_timer}}}
  export bb_size_factor=${args_bb_size_factor:-${workload_size_factor_bb:-${default_bb_size_factor}}}
  export bb_threads=${args_bb_threads:-${workload_threads:-${default_bb_threads}}}
  export bb_batchsize=${args_bb_batchsize:-${workload_batchsize:-${default_bb_batchsize}}}

  export bb_param_changed=0
  if [ "${bb_rate}" != "${workload_rate_bb}" ]; then bb_param_changed=1; fi
  if [ "${bb_timer}" != "${workload_timer_bb}" ]; then bb_param_changed=1; fi
  if [ "${bb_size_factor}" != "${workload_size_factor_bb}" ]; then bb_param_changed=1; fi
  if [ "${bb_threads}" != "${workload_threads}" ]; then bb_param_changed=1; fi
  if [ "${bb_batchsize}" != "${workload_batchsize}" ]; then bb_param_changed=1; fi

  # value check
  if [ "${bb_rate}" = "0" ]; then bb_rate="unlimited"; fi
}
