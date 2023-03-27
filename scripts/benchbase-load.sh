#!/usr/bin/env bash 
LOC=${1:-SRC}
CFG_DIR=${2:-/tmp}

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

# switch into right dir
bb_chdir() {
    db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
    db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
    db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
    jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
    jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
    db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
    db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" ) 

    case ${db_grp,,} in
        mysql)
            pushd /opt/benchbase/benchbase-mariadb
            ;;
        postgresql)
            pushd /opt/benchbase/benchbase-postgres
            ;;
        sqlserver)
            pushd /opt/benchbase/benchbase-sqlserver
            ;;
        informix)
            pushd /opt/benchbase/benchbase-informix
            ;;
        *)
            echo "benchbase-load.sh: ${db_grp} unsupported" >&2
            return 1
            ;;
    esac        
}

# removed: noop 
# conflicts with ycsb: ycsb
# conflict with tpcc: auctionmark epinions seats 
# queries only: chbenchmark hyadapt otmetrics tpcds tpch
workloads="resourcestresser sibench smallbank tatp tpcc twitter voter wikipedia"

# sqlserver bulk copy does not work with these
# workloads="smallbank twitter wikipedia"


# list tables for each workloads
bb_create_tables() {
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/sample_${w}_config.xml --create=true --load=false --execute=false
    done    
    list_tables src | xargs -Ixxx echo xxx $w
}

bb_load_tables() {
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/sample_${w}_config.xml --create=false --load=true --execute=false
    done    
    count_all_tables src
}

bb_run_tables() {
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/sample_${w}_config.xml --create=false --load=false --execute=run &
    done    
}

bb_chdir
bb_create_tables
bb_load_tables
trap kill_jobs SIGINT
wait_jobs
popd