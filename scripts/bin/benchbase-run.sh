#!/usr/bin/env bash 

# get the setting from the menu
if [ -n "${CFG_DIR}" ] && [ -f "${CFG_DIR}/ini_menu.sh" ]; then
    echo "sourcing . ${CFG_DIR}/ini_menu.sh"
    . ${CFG_DIR}/ini_menu.sh
elif [ -f /tmp/ini_menu.sh ]; then
    echo "sourcing . /tmp/ini_menu.sh"
    . /tmp/ini_menu.sh
else
    echo "CFG_DIR=${CFG_DIR} or /tmp/ini_menu.sh did not have ini_menu.sh" >&2
    exit 1
fi   

# rest of libs
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh
. ${SCRIPTS_DIR}/lib/job_control.sh
. ${SCRIPTS_DIR}/lib/benchbase_globals.sh
. ${SCRIPTS_DIR}/lib/benchbase_args.sh
. ${SCRIPTS_DIR}/lib/benchbase_utils.sh

# removed: noop 
# conflicts with ycsb: ycsb
# conflict with tpcc: auctionmark epinions seats 
# queries only: chbenchmark hyadapt otmetrics tpcds tpch
# error when run from program but ok run manually: wikipedia
workloads_default="resourcestresser sibench smallbank tatp tpcc twitter voter ycsb"

# sqlserver bulk copy does not work with these
# workloads="smallbank twitter wikipedia"

sid_db=${SRCDB_SID:-${SRCDB_DB}}
db_schema=${SRCDB_DB:-${SRCDB_SCHEMA}}
db_schema_lower=${db_schema,,}

#if [ "${SRCDB_ARC_USER}" != "${db_schema_lower}" ]; then
#  echo "benchbase-run: "${SRCDB_ARC_USER}" != "${db_schema_lower} skipping
#  exit
#fi

trap kill_jobs SIGINT
bb_run_src "$@"
wait_jobs
