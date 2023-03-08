#!/usr/bin/env bash 

# defaults for the command line
export default_snapshot_thread_ratio=1:1
export default_cdc_thread_ratio=1:1
export default_workload_rate=1
export default_workload_threads=1
export default_workload_timer=600
export default_workload_size_factor=1
export default_gui_run=0

export default_max_cpus=$(getconf _NPROCESSORS_ONLN)
[ -z "${default_max_cpus}" ] && default_max_cpus=1  

# export default_ARCION_ARGS="--replace-existing --overwrite --verbose"
export default_ARCION_ARGS="--truncate-existing --overwrite --verbose"

export default_TMUX_SESSION=arcion

# command line arguments with defaults if not set
export snapshot_thread_ratio=${snapshot_thread_ratio:-$default_snapshot_thread_ratio}
export cdc_thread_ratio=${cdc_thread_ratio:-$default_cdc_thread_ratio}
export workload_rate=${workload_rate:-$default_workload_rate}
export workload_threads=${workload_threads:-$default_workload_threads}
export workload_timer=${workload_timer:-$default_workload_timer}
export workload_size_factor=${workload_size_factor:-$default_workload_size_factor}
export gui_run=${gui_run:-$default_gui_run}
export max_cpus=${max_cpus:-$default_max_cpus}

export TMUX_SESSION=${TMUX_SESSION:-$default_TMUX_SESSION}
export ARCION_ARGS=${ARCION_ARGS:-$default_ARCION_ARGS}

# constants

arcdemo_usage() {
cat <<EOF >&2
$0: arcdemo [snapshot|real-time|full|delta-snapshot] [src_hostname_uri] [dst_hostname] 
  flags
    -g run using GUI=${gui_run}
  params
    -b snapshot_thread_ratio=${snapshot_thread_ratio}
    -c cdc_thread_ratio=${cdc_thread_ratio}
    -m max_cpus=${max_cpus}
    -r workload_rate=${workload_rate}
    -t workload_threads=${workload_threads}
    -w workload_timer=${workload_timer}
    -s workload_size_factor=${workload_size_factor}

Examples:
    snapshot replication from postgresql to mysql 
        SRCDB_HOST postgresql-1
        SRCDB_DIR  postgresql/large

        $0 snapshot postgresq-1/large mysql 

    real-time replication from mysql to mariadb 
        $0 real-time mysql mariadb

    full replication from mysql to mariadb 
        $0 full mysql mariadb

    delta-snapshot replication from mysql to mariadb 
        $0 full mysql mariadb  
EOF
}

function arcdemo_opts() {
  # these are args that can be overridden from the command line
  # override from command line
  local opt
  while getopts "hga:b:c:m:r:s:t:w:" opt; do
      case $opt in
            # flag args
            g ) export gui_run=1 ;;
            # value args
            a ) export ARCION_ARGS="$OPTARG" ;;
            b ) export snapshot_thread_ratio="$OPTARG" ;;
            c ) export cdc_thread_ratio="$OPTARG" ;;
            m ) export max_cpus="$OPTARG" ;;
            r ) export workload_rate="$OPTARG" ;;
            t ) export workload_threads="$OPTARG" ;;
            w ) export workload_timer="$OPTARG" ;;
            s ) export workload_size_factor="$OPTARG" ;;
            h | * ) export arcdemo_usage; exit 1 ;;
      esac
  done
  # basic validataion of values
  [ "$workload_threads" = "0" ] && workload_threads=$default_max_cpus
}