#!/usr/bin/env bash 

. ${SCRIPTS_DIR}/lib/map_csv.sh
. ${SCRIPTS_DIR}/lib/benchbase_globals.sh
. ${SCRIPTS_DIR}/lib/benchbase_args.sh

bb_logging() {
    if [ -f "log4j.properties" ]; then
        export JAVA_OPTS="$JAVA_OPTS -Dlog4j.configuration=file:log4j.properties"        
    fi    
}

# switch into right dir
bb_chdir() {

    #if [ -d /opt/benchbase/benchbase-arcion ]; then 
    #    pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
    #    return 0
    #fi

    case ${db_benchbase_type,,} in
        db2)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-db2 >/dev/null || exit
            ;;
        cockroachdb)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-cockroachdb >/dev/null ;;
            ;;            
        informix)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-informix >/dev/null ;;
            ;;            
        mariadb|mysql|singlestore)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-mariadb >/dev/null ;;
            ;;            
        oracle)
            export JAVA_OPTS="-Doracle.jdbc.timezoneAsRegion=false"        
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-oracle >/dev/null;;
            ;;            
        postgres)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-postgres >/dev/null ;;
            ;;            
#        snowflake)
#                pushd /opt/benchbase/benchbase-snowflake >/dev/null
#            ;;
        sqlserver)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-sqlserver >/dev/null
            ;;           
        sybasease)
            pushd /opt/benchbase/benchbase-arcion >/dev/null || exit
            #pushd /opt/benchbase/benchbase-cockroachdb >/dev/null ;;    
            ;;            
        *)
            echo "benchbase-load.sh: db_benchbase_type='${db_benchbase_type}' unsupported" >&2
            return 1
            ;;
    esac        
}

# list tables for each workloads
bb_create_tables() {
    local LOC="${bb_loc}"
    local workloads="${bb_modules_csv}"

    # DEBUG
    echo "benchbase worload: ${workloads}"
    echo "benchbase db group: $db_grp"
    echo "benchbase db type: $db_type"
    echo "benchbase db batch rewrite: $db_jdbc_no_rewrite"

    # NOTE: <<<$workloads add newline on the last element. 
    # use < <(printf '%s' "$workloads") to fix that 
    readarray -td, workloads_array < <(printf '%s' "$workloads")

    if ! bb_chdir; then return; fi

    declare -A "EXISITNG_TAB_HASH=( $( list_tables ${LOC,,} | \
        awk -F',' '{print "[" $2 "]=" $2}' | tr '[:upper:]' '[:lower:]') )"
    # hash of [workload]=workload,table_name,dbname_suffix,no_rewrite_support
    declare -A "WORKLOAD_TABLE_HASH=( $( cat ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv | \
        awk -F',' '{printf "[%s]=\"%s\"\n", $1,$0}' ) )"
    local workload_prof_header_csv=${WORKLOAD_TABLE_HASH["workload"]}

    for w in "${workloads_array[@]}"; do

        # skip unknown modules
        if [ -z "${WORKLOAD_TABLE_HASH[$w]}" ]; then
            echo "bb_create_tables: ignoring $w"
            continue
        fi  

        declare -A workload_prof_dict=()
        csv_as_dict workload_prof_dict "${workload_prof_header_csv}" "${WORKLOAD_TABLE_HASH[$w]}"
        # DEBUG 
        declare -p workload_prof_dict
        local dbname_suffix=${workload_prof_dict[dbname_suffix]}

        # save the list of existing tables as bash associative array (the -A)
        # NOTE: the quote is required to create the hash correctly
        # hash of [tablename]=tablename
        if [[ "${LOC,,}" = "src" ]]; then 
            local SRCDB_ARC_USER=${SRCDB_ARC_USER}${dbname_suffix}; 
            local SRCDB_DB=${SRCDB_ARC_USER}${dbname_suffix}; 
        else 
            local DSTDB_ARC_USER=${DSTDB_ARC_USER}${dbname_suffix}; 
            local DSTDB_DB=${DSTDB_ARC_USER}${dbname_suffix}; 
        fi

        #echo ${EXISITNG_TAB_HASH[@]}
        #echo ${WORKLOAD_TABLE_HASH[@]}

        echo "Checking table create required for $w"

        cat $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml > $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$
        # remove batch rewrite
        remove_batchrwrite=${workload_prof_dict["dont_rewrite_batch"]}
        if [ "$db_grp" = "$remove_batchrwrite" ]; then
            echo "Remove batch rewrite per ${SCRIPTS_DIR}/utils/benchbase/bb_no_batchrewrite.csv"
            if [ -z "$db_jdbc_no_rewrite" ]; then
                echo "no write available"
            else
                sed -i.bak -e "$db_jdbc_no_rewrite" $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$ 
                diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$.bak >&2
            fi 
        fi

        # change default batch size
        local batch_size=${workload_prof_dict[${db_benchbase_type,,}]}
        if [[ -n ${batch_size} ]]; then
            echo "changing batchsize based on ${db_benchbase_type,,} column in ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv"
            sed -i.bak \
                -e "s|\(<batchsize>\).*\(</\)|\1${batch_size}\2|" \
                $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$
            diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$.bak >&2        
        fi

        # a table for this workload
        workload_table=${workload_prof_dict["table_name"]}
        if [ -z "${workload_table}" ]; then
            echo "Skipping: ${w} does not have entry in ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv"
            continue
        fi
        # exist already?
        workload_table_exists=${EXISITNG_TAB_HASH[${workload_table,,}]}
        if [ -z "${workload_table_exists}" ]; then
            # change config match args
            echo "changing username and database name based on ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv"
            sed -i.bak \
                -e "s|\(<username>\).*\(</\)|\1${db_user}${dbname_suffix}\2|" \
                -e "s|#_CHANGEME_#|${db_user}${dbname_suffix}|" \
                $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$
            diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$.bak >&2

            # disable hava debugger
            unset JAVA_TOOL_OPTIONS            
  
            # set debugging options  
            bb_logging
            JAVA_HOME=$( find /usr/lib/jvm/java-17-openjdk-* -maxdepth 0 )   
            $JAVA_HOME/bin/java $JAVA_OPTS \
            -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$ \
            --interval-monitor 10000 \
            --create=true --load=true --execute=false | tee $CFG_DIR/bb-load-${w}.log
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

    # read profile
    declare -A "WORKLOAD_TABLE_HASH=( $( cat ${SCRIPTS_DIR}/utils/benchbase/bbtables.csv | \
        awk -F',' '{printf "[%s]=\"%s\"\n", $1,$0}' ) )"
    local workload_prof_header_csv=${WORKLOAD_TABLE_HASH["workload"]}
    # DEBUG declare -p WORKLOAD_TABLE_HASH return

    # convert csv to array
    readarray -td, workloads_array < <(printf '%s' "$workloads")

    JAVA_HOME=$( find /usr/lib/jvm/java-17-openjdk-* -maxdepth 0 )   
    for w in "${workloads_array[@]}"; do

        if [ -z "${WORKLOAD_TABLE_HASH[$w]}" ]; then
            echo "bb_run_tables: ignoring $w"
            continue
        fi    

        declare -A workload_prof_dict=()
        csv_as_dict workload_prof_dict "${workload_prof_header_csv}" "${WORKLOAD_TABLE_HASH[$w]}"
        # DEBUG
        declare -p workload_prof_dict
        local dbname_suffix=${workload_prof_dict[dbname_suffix]}
        
        cat $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml > $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$
        # change config match args
        sed -i.bak \
            -e "s|\(<username>\).*\(</\)|\1${db_user}${dbname_suffix}\2|" \
            -e "s|#_CHANGEME_#|${db_user}${dbname_suffix}|" \
            -e "s|\(<rate>\).*\(</\)|\1${bb_rate}\2|" \
            -e "s|\(<time>\).*\(</\)|\1${bb_timer}\2|" \
            -e "s|\(<scalefactor>\).*\(</\)|\1${bb_size_factor}\2|" \
            -e "s|\(<terminals>\).*\(</\)|\1${bb_threads}\2|" \
            -e "s|\(<batchsize>\).*\(</\)|\1${bb_batchsize}\2|" \
            $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$
        diff $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$  $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$.bak >&2

        # disable hava debugger
        unset JAVA_TOOL_OPTIONS
        
        # set debugging options
        bb_logging
        # run
        $JAVA_HOME/bin/java  $JAVA_OPTS \
        -jar benchbase.jar -b $w -c $CFG_DIR/benchbase/${LOC,,}/sample_${w}_config.xml.$$ \
        --interval-monitor 10000 \
        --create=false --load=false --execute=true | tee $CFG_DIR/bb-run-${w}.log &
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

bb_load_src() {
  bb_opts "$@"
  bb_src_dst_param "src"    
  bb_create_tables "src"
}

bb_load_dst() {
  bb_opts "$@"
  bb_src_dst_param "dst"    
  bb_create_tables "dst"
}