#!/usr/bin/env bash 

. ${SCRIPTS_DIR}/lib/benchbase_globals.sh
. ${SCRIPTS_DIR}/lib/benchbase_args.sh

# switch into right dir
bb_chdir() {

    case ${db_benchbase_type,,} in
        cockroachdb)
            pushd /opt/benchbase/benchbase-cockroachdb >/dev/null
            ;;
        informix)
            pushd /opt/benchbase/benchbase-informix >/dev/null
            ;;
        mariadb|mysql|singlestore)
            pushd /opt/benchbase/benchbase-mariadb >/dev/null 
            ;;
        oracle)
            export JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false"        
            pushd /opt/benchbase/benchbase-oracle >/dev/null
            ;;
        postgres)
                pushd /opt/benchbase/benchbase-postgres >/dev/null
            ;;
#        snowflake)
#                pushd /opt/benchbase/benchbase-snowflake >/dev/null
#            ;;
        sqlserver)
            pushd /opt/benchbase/benchbase-sqlserver >/dev/null
            ;;
        db2)
            pushd /opt/benchbase/benchbase-db2 >/dev/null
            ;;
        *)
            echo "benchbase-load.sh: ${db_grp} unsupported" >&2
            return 1
            ;;
    esac        
}

# list tables for each workloads
bb_create_tables() {
    local LOC="${bb_loc}"
    local workloads="${bb_modules_csv}"

    # NOTE: <<<$workloads add newline on the last element. 
    # use < <(printf '%s' "$workloads") to fix that 
    readarray -td, workloads_array < <(printf '%s' "$workloads")

    if ! bb_chdir; then return; fi

    # DEBUG
    echo "benchbase worload: ${workloads}"
    echo "benchbase db group: $db_grp"
    echo "benchbase db type: $db_type"
    echo "benchbase db batch rewrite: $db_jdbc_no_rewrite"

    # save the list of existing tables as bash associative array (the -A)
    # NOTE: the quote is required to create the hash correctly
    # hash of [tablename]=tablename
    declare -A "EXISITNG_TAB_HASH=( $( list_tables ${LOC,,} | awk -F, '/^table/ {print "[" $2 "]=" $2}' ) )"
    # hash of [worklaod]=tablename
    declare -A "WORKLOAD_TABLE_HASH=( $( tail -n +2 ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv | sed 's/^\(.*\),\(.*\)$/[\1]=\2/g' ) )"
    # hash of [worklaod]=database that do not work with batchrewrite
    declare -A "WORKLOAD_DATABASE_NOREWRITE_HASH=( $( tail -n +2 ${SCRIPTS_DIR}/utils/benchbase/bb_no_batchrewrite.csv | sed 's/^\(.*\),\(.*\)$/[\1]=\2/g' ) )"

    #echo ${EXISITNG_TAB_HASH[@]}
    #echo ${WORKLOAD_TABLE_HASH[@]}

    for w in "${workloads_array[@]}"; do
        echo "Checking table create required for $w"

        # remove batch rewrite
        remove_batchrwrite=${WORKLOAD_DATABASE_NOREWRITE_HASH[$w]}
        if [ "$db_grp" = "$remove_batchrwrite" ]; then
            echo "Remove batch rewrite per ${SCRIPTS_DIR}/utils/benchbase/bb_no_batchrewrite.csv"
            if [ -z "$db_jdbc_no_rewrite" ]; then
                echo "no write available"
            else
                sed -i.bak -e "$db_jdbc_no_rewrite" $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml
                diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.bak >&2
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
            JAVA_HOME=$( find /usr/lib/jvm/java-17-openjdk-* -maxdepth 0 )   
            $JAVA_HOME/bin/java $JAVA_OPTS \
            -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
            --interval-monitor 10000 \
            --create=true --load=true --execute=false
        else
            # do not drop the existing tables as take time to refill them
            echo "$w: skipping table create $workload_table_exists table exists."
        fi
    done    

    popd >/dev/null || { echo "Error:bb_create_tables: popd filed $(pwd)"; }
}

# $1=SRC|DST
# $2=comma separated list of workload names
bb_run_tables() {
    local LOC="${bb_loc}"
    local workloads="${bb_modules_csv}"
    
    # chdir to where the binary is
    if ! bb_chdir; then return; fi

    # convert csv to array
    readarray -td, workloads_array < <(printf '%s' "$workloads")

    JAVA_HOME=$( find /usr/lib/jvm/java-17-openjdk-* -maxdepth 0 )   
    for w in "${workloads_array[@]}"; do

        # change config match args
        if (( bb_param_changed > 0 )); then
            sed -i.bak \
                -e "s|\(<rate>\).*\(</\)|\1${bb_rate}\2|" \
                -e "s|\(<time>\).*\(</\)|\1${bb_timer}\2|" \
                -e "s|\(<scalefactor>\).*\(</\)|\1${bb_size_factor}\2|" \
                -e "s|\(<terminals>\).*\(</\)|\1${bb_threads}\2|" \
                -e "s|\(<batchsize>\).*\(</\)|\1${bb_batchsize}\2|" \
                $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml
            diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.bak >&2
        fi

        # run
        $JAVA_HOME/bin/java  $JAVA_OPTS \
        -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml \
        --interval-monitor 10000 \
        --create=false --load=false --execute=true &
    done    

    popd >/dev/null || { echo "Error:bb_run_tables: popd filed $(pwd)"; }
}

bb_run_src() {
  bb_opts "$@"
  bb_src_dst_param "src"    
  bb_run_tables "src"
}

bb_run_dst() {
  bb_opts "$@"
  bb_src_dst_param "dst"    
  bb_run_tables "dst"
}