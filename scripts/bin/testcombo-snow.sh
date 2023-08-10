#!/usr/bin/env bash

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-s|--src host ] [-d|--dst host ] [-r|--repltype type] -- [options to pass to arcdemo.sh]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-s, --src       source "uri" separated by space
-d, --dst       destination "uri" separted by space
-r, --repl      repl type: separated by space snapshot real-time full delta-snapshot
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -s | --src) # example named parameter
      args_src="${2-}"
      shift
      ;;
    -d | --dst) # example named parameter
      args_dst="${2-}"
      shift
      ;;
    -r | --repltype) # example named parameter
      args_repl="${2-}"
      shift
      ;;      
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  # check required params and arguments
  # [[ -z "${param-}" ]] && die "Missing required parameter: param"
  # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

loop_run() {
  local repl="${1}"
  local src="${2}"
  local dst="${3}"
  for sf in "${sfs[@]}"; do 
    for t in "${threads[@]}"; do 
      for r in "${repl[@]}"; do
        src=($src)
        dst=($dst)
        for s in "${src[@]}"; do
          for d in "${dst[@]}"; do
              echo "./arcdemo.sh $sf $t $r $s $d"
              SRCDB_DB=arcsrc ./arcdemo.sh $sf $t $r $s $d
          done
        done
      done
    done
  done
}

args_src=""
args_dst=""
args_repl=""

parse_params "$@"

cdc_src="ase db2 informix mariadb mysql oraee oraxe pg sqlserver"
all_src="ase cockroach db2 informix mariadb mysql oraee oraxe pg s2 sqledge sqlserver yugabytesql"
all_dst="cockroach informix kafka mariadb minio mysql null oraee pg redis s2 sqledge sqlserver yugabytesql"

sfs=("-s 1 -w 1200:300")  # scale factor
threads=("-b 1:1 -c 1:1 -r 0")    # threading
src=${args_src:-${all_src}}  # source
dst=${args_dst:-${all_dst}}
repl=${args_repl:-"snapshot real-time full"} # replication types

# change to array
repl=($repl)

export PAUSE_SECONDS=1

for r in "${repl[@]}"; do
  echo $r
  case ${r} in
    snapshot)
      loop_run ${r} "snowflake" "${all_dst}"
      loop_run ${r} "${all_src}" "snowflake" 
      ;;
    real-time|full)
      # loop_run ${r} "snowflake" "${all_dst}"
      loop_run ${r} "${cdc_src}" "snowflake" 
      ;;
  esac
done