#!/usr/bin/env bash 

# switch into right dir
bb_chdir() {
    local LOC=${1:-SRC}

    db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )
    db_type=$( x="${LOC^^}DB_TYPE"; echo "${!x}" )
    db_jdbc_no_rewrite=$( x="${LOC^^}DB_JDBC_NO_REWRITE"; echo "${!x}" )

    #db_user=$( x="${LOC^^}DB_ARC_USER"; echo "${!x}" )
    #db_pw=$( x="${LOC^^}DB_ARC_PW"; echo "${!x}" )
    #jdbc_url=$( x="${LOC^^}DB_JDBC_URL"; echo "${!x}" )
    #jdbc_driver=$( x="${LOC^^}DB_JDBC_DRIVER"; echo "${!x}" )
    #db_host=$( x="${LOC^^}DB_HOST"; echo "${!x}" )
    #db_port=$( x="${LOC^^}DB_PORT"; echo "${!x}" ) 

    case ${db_grp,,} in
        informix)
            pushd /opt/benchbase/benchbase-informix >/dev/null
            ;;
        mysql)
            pushd /opt/benchbase/benchbase-mariadb >/dev/null 
            ;;
        oracle)
            pushd /opt/benchbase/benchbase-oracle >/dev/null
            ;;
        postgresql)
            pushd /opt/benchbase/benchbase-postgres >/dev/null
            ;;
        sqlserver)
            pushd /opt/benchbase/benchbase-sqlserver >/dev/null
            ;;
        *)
            echo "benchbase-load.sh: ${db_grp} unsupported" >&2
            return 1
            ;;
    esac        
}

# list tables for each workloads
bb_create_tables() {
    local LOC=${1:-SRC}
    local workloads="${2:-tpcc}"

    # DEBUG
    echo "benchbase worload: ${workloads}"
    echo "benchbase db group: $db_grp"
    echo "benchbase db type: $db_type"
    echo "benchbase db batch rewrite: $db_jdbc_no_rewrite"

    # NOTE: <<<$workloads add newline on the last element. 
    # use < <(printf '%s' "$workloads") to fix that 
    readarray -td, workloads < <(printf '%s' "$workloads")

    bb_chdir $LOC

    # save the list of existing tables as bash associative array (the -A)
    # NOTE: the quote is required to create the hash correctly
    # hash of [tablename]=tablename
    declare -A "EXISITNG_TAB_HASH=( $( list_tables ${LOC,,} | tr  '[:upper:]' '[:lower:]' | awk -F, '/^table/ {print $2}' | sort | sed 's/[^ ]*/[&]=&/g' | paste -s ) )"
    # hash of [worklaod]=tablename
    declare -A "WORKLOAD_TABLE_HASH=( $( tail -n +2 ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv | sed 's/^\(.*\),\(.*\)$/[\1]=\2/g' ) )"
    # hash of [worklaod]=database that do not work with batchrewrite
    declare -A "WORKLOAD_DATABASE_NOREWRITE_HASH=( $( tail -n +2 ${SCRIPTS_DIR}/utils/benchbase/bb_no_batchrewrite.csv | sed 's/^\(.*\),\(.*\)$/[\1]=\2/g' ) )"

    #echo ${EXISITNG_TAB_HASH[@]}
    #echo ${WORKLOAD_TABLE_HASH[@]}

    for w in "${workloads[@]}"; do
        echo "Checking table create required for $w"

        # remove batch rewrite
        remove_batchrwrite=${WORKLOAD_DATABASE_NOREWRITE_HASH[$w]}
        if [ "$db_grp" = "$remove_batchrwrite" ]; then
            echo "Remove batch rewrite per ${SCRIPTS_DIR}/utils/benchbase/bb_no_batchrewrite.csv"
            if [ -z "$db_jdbc_no_rewrite" ]; then
                echo "no write available"
            else
                sed -i.bak -e "$db_jdbc_no_rewrite" $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml
                diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.bak $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml 
            fi 
        fi

        # a table for this workload
        workload_table=${WORKLOAD_TABLE_HASH[$w]}
        if [ -z "${workload_table}" ]; then
            echo "Skipping: ${w} does not have entry in ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv"
            continue
        fi
        # exist already?
        workload_table_exists=${EXISITNG_TAB_HASH[$workload_table]}
        if [ -z "${workload_table_exists}" ]; then
            JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
            $JAVA_HOME/bin/java -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
            --interval-monitor 10000 \
            --create=true --load=true --execute=false
        else
            # do not drop the existing tables as take time to refill them
            echo "$w: skipping table create $workload_table_exists table exists."
        fi
    done    

    popd >/dev/null
}

bb_run_tables() {
    local LOC=${1:-SRC}
    local workloads="${2:-tpcc}"

    bb_chdir $LOC

    readarray -td, workloads < <(printf '%s' "$workloads")

    for w in "${workloads[@]}"; do
        JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"    
        $JAVA_HOME/bin/java \
        -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
        --interval-monitor 10000 \
        --create=false --load=false --execute=true &
    done    

    popd >/dev/null

}
