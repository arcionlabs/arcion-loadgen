#!/usr/bin/env bash 

# switch into right dir
bb_chdir() {
    local LOC=${1:-SRC}

    db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )

    #db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
    #db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
    #jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
    #jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
    #db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
    #db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" ) 

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

# list tables for each workloads
bb_create_tables() {
    local workloads="${1:-tpcc}"
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
        --create=true --load=false --execute=false
    done    
    list_tables ${LOC,,} | xargs -Ixxx echo xxx $w
}

bb_load_tables() {
    local workloads="${1:-tpcc}"
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
        --interval-monitor 10000 \
        --create=false --load=true --execute=false
    done    
    count_all_tables ${LOC,,}
}

bb_run_tables() {
    local workloads="${1:-tpcc}"
    for w in $workloads; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java \
        -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
        --interval-monitor 10000 \
        --create=false --load=false --execute=true &
    done    
}