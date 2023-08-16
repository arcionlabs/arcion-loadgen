#/usr/bin/env bash

. $SCRIPTS_DIR/lib/job_control.sh || exit 1

# wait for jobs to finish for ctrl-c to exit
control_c() {
    # give chance to quiet down
    echo "Waiting 5 sec for CDC to finish" >&2
    sleep 5
    kill_jobs
    kill_recurse $ARCION_PID  # required as catch all
}

# return command parm given source and target pair
arcion_param() {
    local src_dir=${1:-.}
    local dst_dir=${2:-$src_dir}
    local meta_dir=${3:-$src_dir}
    local arg=""
    
    # source specific
    src=$(find ${src_dir} -maxdepth 1 -name src.yaml -print)
    filter=$(find ${src_dir} -maxdepth 1 -name src_filter.yaml -print)
    extractor=$(find ${src_dir} -maxdepth 1 -name src_extractor.yaml -print)

    # dest specific
    dst=$(find ${dst_dir} -maxdepth 1 -name dst.yaml -print)
    applier=$(find ${dst_dir} -maxdepth 1 -name dst_applier.yaml -print)
    map=$(find ${dst_dir} -maxdepth 1 -name dst_map.yaml -print)

    # global
    general=$(find ${dst_dir} -maxdepth 1 -name general.yaml -print)

    # optional
    if [ -n "${meta_dir}" ]; then
        metadata=$(find ${meta_dir} -maxdepth 1 -name metadata.yaml -print | head -n 1 )
    fi

    # check
    if [[ -z ${src} ]]; then echo "Error: src.yaml was not found" >&2; exit 1; fi
    if [[ -z ${dst} ]]; then echo "Error: dst.yaml was not found" >&2; exit 1; fi

    # construct the list
    arg="${src} ${dst}"
    [ -n "${filter}" ] && arg="${arg} --filter ${filter}"
    [ -n "${extractor}" ] && arg="${arg} --extractor ${extractor}"
    [ -n "${applier}" ] && arg="${arg} --applier ${applier}"
    [ -n "${map}" ] && arg="${arg} --map ${map}"
    [ -n "${metadata}" ] && arg="${arg} --metadata ${metadata}"
    [ -n "${general}" ] && arg="${arg} --general ${general}"

    echo "$arg" 
}

logreader_path() {
    # amd64 or arm64 
    JAVA_HOME=$( find /usr/lib/jvm/java-8-openjdk-*/jre -maxdepth 0)

    case "${SRCDB_GRP,,}" in
        db2)
            PATH="/home/arcion/sqllib/bin:$PATH"
            . ~/sqllib/db2profile
            JAVA_OPTS="-Djava.library.path=lib"        
            ;;
        oracle)
            ORACLE_HOME=/opt/oracle
            LD_LIBRARY_PATH="$ORACLE_HOME/lib":$LD_LIBRARY_PATH
            PATH="$ORACLE_HOME/lib:$ORACLE_HOME/bin:$PATH"    
            ;;
    esac

    case "${SRCDB_TYPE,,}" in
        mysql)
            PATH="/opt/mysql/usr/bin:$PATH"
            ;;
        mariadb)
            PATH="/opt/mariadb/usr/bin:$PATH"
            ;;
    esac
}

run_arcion() {
    # do not run if gui will be used to invoke
    if [ "${gui_run}" = "1" ]; then 
        echo "GUI running Arcion.  Waiting for the timeout" >> $CFG_DIR/arcion.log
        return 0; 
    fi

    pushd $ARCION_HOME >/dev/null

    # required for Arcion
    logreader_path

    # expand options
    ARC_OPTS=$( arcion_param ${CFG_DIR} ) \

    cat <<EOF
JAVA_HOME="$JAVA_HOME" JAVA_OPTS="$JAVA_OPTS" ORACLE_HOME="$ORACLE_HOME" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" PATH="$PATH" ./bin/replicant $REPL_TYPE ${ARC_OPTS} ${ARCION_ARGS} --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &
EOF

    JAVA_HOME="$JAVA_HOME" \
    JAVA_OPTS="$JAVA_OPTS" \
    ORACLE_HOME="$ORACLE_HOME" \
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH" \
    PATH="$PATH" \
    ./bin/replicant $REPL_TYPE \
    ${ARC_OPTS} \
    ${ARCION_ARGS} \
    --id $LOG_ID >> $CFG_DIR/arcion.log 2>&1 &

    # $! process ID of the job most recently placed into the background
    export ARCION_PID=$!
    popd >/dev/null
}

(return 0 2>/dev/null) && sourced=1 || sourced=0

if (( sourced == 0)); then 
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

    run_arcion
    tail -f $CFG_DIR/arcion.log &

    # allow ctl-c to terminate background jobs
    trap control_c SIGINT

    # wait for background jobs to finish
    jobs_left=$( wait_jobs "0" "$ARCION_PID" )
fi