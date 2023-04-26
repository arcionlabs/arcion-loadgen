#!/usr/bin/env bash 
LOC=${1:-SRC}
WORKLOADS=${2}
CFG_DIR=${3:-/tmp}

# load the init file
if [ -f "${CFG_DIR}/ini_menu.sh" ]; then
    . ${CFG_DIR}/ini_menu.sh
else
    echo "CFG_DIR=${CFG_DIR} did not have ini_menu.sh" >&2
    exit 1
fi     

# rest of libs
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh
. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/benchbase_utils.sh

# removed: noop 
# conflicts with ycsb: ycsb
# conflict with tpcc: auctionmark epinions seats 
# queries only: chbenchmark hyadapt otmetrics tpcds tpch
# error when run from program but ok run manuall: wikipedia
workloads_default="resourcestresser,sibench,smallbank,tatp,tpcc,twitter,voter,ycsb"

# sqlserver bulk copy does not work with these
# workloads="smallbank twitter wikipedia"

if [ "${SRCDB_ARC_USER}" != "${SRCDB_DB:-${SRCDB_SCHEMA}}" ]; then
  echo "benchbase-load: "${SRCDB_ARC_USER}" != "${SRCDB_DB:-${SRCDB_SCHEMA}} skipping
  exit
fi

trap kill_jobs SIGINT
if [ -z "$WORKLOADS" ]; then 
    bb_create_tables $LOC "$workload_modules_bb"
else
    bb_create_tables $LOC "$WORKLOADS"
fi
wait_jobs
