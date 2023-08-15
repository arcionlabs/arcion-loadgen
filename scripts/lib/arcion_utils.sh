#!/usr/bin/env bash 

. ${SCRIPTS_DIR}/lib/ping_utils.sh
. ${SCRIPTS_DIR}/lib/map_csv.sh

# $1=yaml file
is_host_up() {
    local host=$( yq -r ".host" src.yaml )    
}

# find source DB dir that has src.yaml, filter.yaml and extractor.yarm
find_srcdb() {
    find * -type f \( -iname "src.yaml" -o -iname "src_filter*.yaml" -o -iname "src_extractor.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do if (( count == 3 )); then echo $dir; fi; done 
}
# find dst DB dir that has dst.yaml, applier.yaml 
find_dstdb() {
    find * -type f \( -iname "dst.yaml" -o -iname "dst_applier.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do 
        if (( count == 2 )); then echo $dir; fi; 
    done
}

save_nmap() {
    mkdir -p /tmp/arcion/nmap

    local subnet=$( hostname -I | awk -F'.' '{print $1 "." $2 "." $3 "." 0 "/24"}' )
    # don't spend more than 2 sec
    nmap -sn -oG /tmp/arcion/nmap/nmap.raw.txt $subnet >/dev/null
    
    # save in hostname (without trailing .arcnet) ip
    cat /tmp/arcion/nmap/nmap.raw.txt | \
        awk -F"[ ()]" '/arcnet/ {print $4 "," $2}' | \
        sed 's/\.arcnet//' | \
        tee /tmp/arcion/nmap/name.ip.csv
}

find_hosts() {
    if [ ! -f "/tmp/arcion/nmap/name.ip.csv" ]; then
        save_nmap
    fi
    local host_ip=$(cat /tmp/arcion/nmap/name.ip.csv | awk -F',' '{print $1}')
    if [[ -z "${host_ip}" ]]; then
        echo "refreshing nmap" >&2
        save_nmap
        host_ip=$(cat /tmp/arcion/nmap/name.ip.csv | awk -F',' '{print $1}')
    fi
    echo ${host_ip}
}

ask_src_host() {
    PS3="Please enter the SOURCE host: "
    echo $PS3
    options=( $(find_hosts) )
    select SRCDB_HOST in "${options[@]}"; do
        if [ ! -z "$SRCDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_HOST
}
ask_dst_host() {
    PS3='Please enter the DESTINATION host: '
    echo $PS3
    options=( $(find_hosts) )
    select DSTDB_HOST in "${options[@]}"; do
        if [ ! -z "$DSTDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_HOST
}
ask_src_dir() {
    PS3='Please enter the source dir: '
    options=( $(find_srcdb) )
    select SRCDB_DIR in "${options[@]}"; do
        if [ -d "$SRCDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_DIR
}
ask_dst_dir() {
    PS3='Please enter the target: '
    options=( $(find_dstdb) )
    select DSTDB_DIR in "${options[@]}"; do
        if [ -d "$DSTDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_DIR
}
ask_repl_mode() {
    PS3='Please enter the replication type: '
    options=( "snapshot" "full" "real-time" "delta-snapshot" )
    select REPL_TYPE in "${options[@]}"; do
        if [ ! -z "$REPL_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export REPL_TYPE
}
init_src() {
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0

    mkdir -p $CFG_DIR/exit_status

    figlet -t $SRCDB_HOST
    for f in $( find $CFG_DIR -maxdepth 1 -name "src.init*sh" | xargs -I%% basename %% .sh | sort --version-sort ); do
        f="$f.sh"
        echo "Running $f"
        # NOTE: do not remove () below as that will exit this script
        #( exec ${f} 2>&1 | tee -a $f.log )
        # run src.ini.sh 
        $CFG_DIR/${f} 2>&1 | tee -a $f.log
        rc=${PIPESTATUS[0]}
        echo "$rc" > $CFG_DIR/exit_status/init_src.log
        if [ "$rc" != 0 ]; then break; fi  
    done
    figlet -t $SRCDB_HOST
    return $rc
}
init_dst() {
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0    

    mkdir -p $CFG_DIR/exit_status

    figlet -t $DSTDB_HOST
    for f in $( find $CFG_DIR -maxdepth 1 -name "dst.init*sh" | xargs -I%% basename %% .sh | sort --version-sort ); do
        f="$f.sh"
        echo "Running $f"
        # NOTE: do not remove () below as that will exit this script
        # ( exec ${f} 2>&1 | tee -a $f.log ) 
        $CFG_DIR/${f} 2>&1 | tee -a $f.log
        # DEBUG declare -p PIPESTATUS >&2
        rc=${PIPESTATUS[0]}
        echo "$rc" > $CFG_DIR/exit_status/init_dst.log
        if [ "$rc" != 0 ]; then break; fi  
    done
    figlet -t $DSTDB_HOST
    return $rc
}

set_src() {
# source
SRCDB_HOST_old=${SRCDB_HOST}
SRCDB_DIR_old=${SRCDB_DIR}
SRCDB_TYPE_old=${SRCDB_TYPE}
SRCDB_GRP_old=${SRCDB_GRP}
SRCDB_PORT_old=${SRCDB_PORT}
SRCDB_ROOT_old=${SRCDB_ROOT}

while [ 1 ]; do
    clear
    echo "Setting up Source Host and Type"
    ask=0
    [ -z "${SRCDB_TYPE}" ] && export SRCDB_TYPE=${SRCDB_PROFILE_DICT[type]}
    [ -z "${SRCDB_GRP}" ] && export SRCDB_GRP=${SRCDB_PROFILE_DICT[group]}
    [ -z "${SRCDB_PORT}" ] && export SRCDB_PORT=${SRCDB_PROFILE_DICT[port]}
    [ -z "${SRCDB_ROOT}" ] && export SRCDB_ROOT=${SRCDB_PROFILE_DICT[root_user]}
    [ -z "${SRCDB_PW}" ] && export SRCDB_PW=${SRCDB_PROFILE_DICT[root_pw]}
    [ -z "${SRCDB_SID}" ] && export SRCDB_SID=${SRCDB_PROFILE_DICT[sid]}
    [ -z "${SRCDB_ROOT_DB}" ] && export SRCDB_ROOT_DB=${SRCDB_PROFILE_DICT[root_db]}
    [ -z "${SRCDB_CASE}" ] && export SRCDB_CASE=${SRCDB_PROFILE_DICT[case]}

    [ -z "${SRCDB_DIR}" ] && export SRCDB_DIR=${SRCDB_PROFILE_DICT[config_dir]}
    if [ -z "${SRCDB_DIR}" ]; then export SRCDB_DIR=$( infer_dbdir SRCDB_PROFILE_DICT "${SRCDB_HOST}"); fi
    if [ -z "${SRCDB_DIR}" ] || [ ! -d "${SRCDB_DIR}" ]; then ask=1; ask_src_dir; fi
    if [ -n "${SRCDB_SUBDIR}" ]; then SRCDB_DIR=${SRCDB_DIR}/${SRCDB_SUBDIR}; fi
    
    [ -z "${SRCDB_INIT_DIR}" ] && export SRCDB_INIT_DIR=${SRCDB_PROFILE_DICT[init_dir]}
    if [ -z "${SRCDB_INIT_DIR}" ]; then export SRCDB_INIT_DIR=$SRCDB_GRP; fi

    case "${SRCDB_GRP,,}" in
        snowflake)
            SRCDB_HOST="${SNOW_SRC_ENDPOINT}" 
            SRCDB_PORT="${SNOW_SRC_PORT:-443}" 
            SRCDB_ARC_USER="${SNOW_SRC_ID}" 
            SRCDB_ARC_PW="${SNOW_SRC_SECRET}"                 
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER^^}
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA=${SRCDB_PROFILE_DICT[schema]}
            ;;
        informix)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA="${SRCDB_ARC_USER}"
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER}
        ;;
        db2)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA="${SRCDB_ARC_USER^^}"
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA^^}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER^^}
        ;;
        oracle)
            export SRCDB_ARC_USER="c##${SRCDB_ARC_USER}"
            export SRCDB_SCHEMA="${SRCDB_ARC_USER^^}"
            export SRCDB_COMMA_SCHEMA=${SRCDB_SCHEMA^^}
            export SRCDB_DB=""

            export ORA_LOG_PATH=${SRCDB_PROFILE_DICT[log_path]}
            export ORA_ARCH_LOG_PATH=${SRCDB_PROFILE_DICT[archive_log_path]}
            export ORA_ALT_LOG_PATH=${SRCDB_PROFILE_DICT[alt_log_path]}
            export ORA_ALT_ARCH_LOG_PATH=${SRCDB_PROFILE_DICT[alt_archive_log_path]}   
        ;;
        *)
            [ -z "${SRCDB_SCHEMA}" ] && export SRCDB_SCHEMA=${SRCDB_PROFILE_DICT[schema]}
            [ ! -z "${SRCDB_SCHEMA}" ] && export SRCDB_COMMA_SCHEMA=",${SRCDB_SCHEMA}"
            [ -z "${SRCDB_DB}" ] && export SRCDB_DB=${SRCDB_ARC_USER}
        ;; 
    esac

    [ -z "${SRCDB_BENCHBASE_TYPE}" ] && export SRCDB_BENCHBASE_TYPE=${SRCDB_PROFILE_DICT[benchbase_type]}
    [ -z "${SRCDB_JDBC_ISOLATION}" ] && export SRCDB_JDBC_ISOLATION=${SRCDB_PROFILE_DICT[benchbase_txn_isolation]}

    # safeguard RAM for the demo
    case "${SRCDB_TYPE,,}" in
        singlestore)
            workload_size_factor_bb=1
            echo "singlestore: setting workload_size_factor_bb=1"
            ;;
    esac

    echo "Source DB Config:"
    set | grep "^SRCDB_" | grep -v "_old="

    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            SRCDB_HOST=${SRCDB_HOST_old}
            SRCDB_DIR=${SRCDB_DIR_old} 
            SRCDB_TYPE=${SRCDB_TYPE_old} 
            SRCDB_GRP=${SRCDB_GRP_old}
            SRCDB_PORT=${SRCDB_PORT_old}                
            SRCDB_ROOT=${SRCDB_ROOT_old}                
        fi
    fi
done
}

# destination
set_dst() {
DSTDB_HOST_old=${DSTDB_HOST}
DSTDB_TYPE_old=${DSTDB_TYPE}
DSTDB_DIR_old=${DSTDB_DIR}
DSTDB_GRP_old=${DSTDB_GRP}
DSTDB_PORT_old=${DSTDB_PORT}
DSTDB_ROOT_old=${DSTDB_ROOT}
while [ 1 ]; do
    clear
    echo "Setting up Target Host and Type"
    ask=0
    [ -z "${DSTDB_TYPE}" ] && export DSTDB_TYPE=${DSTDB_PROFILE_DICT[type]}
    [ -z "${DSTDB_GRP}" ] && export DSTDB_GRP=${DSTDB_PROFILE_DICT[group]}
    [ -z "${DSTDB_PORT}" ] && export DSTDB_PORT=${DSTDB_PROFILE_DICT[port]}
    [ -z "${DSTDB_ROOT}" ] && export DSTDB_ROOT=${DSTDB_PROFILE_DICT[root_user]}
    [ -z "${DSTDB_PW}" ] && export DSTDB_PW=${DSTDB_PROFILE_DICT[root_pw]}
    [ -z "${DSTDB_SID}" ] && export DSTDB_SID=${DSTDB_PROFILE_DICT[sid]}
    [ -z "${DSTDB_ROOT_DB}" ] && export DSTDB_ROOT_DB=${DSTDB_PROFILE_DICT[root_db]}
    [ -z "${DSTDB_CASE}" ] && export DSTDB_CASE=${DSTDB_PROFILE_DICT[case]}

    [ -z "${DSTDB_DIR}" ] && export DSTDB_DIR=${DSTDB_PROFILE_DICT[config_dir]}
    if [ -z "${DSTDB_DIR}" ]; then export DSTDB_DIR=$( infer_dbdir DSTDB_PROFILE_DICT "${DSTDB_HOST}"); fi
    if [ -z "${DSTDB_DIR}" ] || [ ! -d "${DSTDB_DIR}" ]; then ask=1; ask_dst_dir; fi
    if [ -n "${DSTDB_SUBDIR}" ]; then DSTDB_DIR=${DSTDB_DIR}/${DSTDB_SUBDIR}; fi
    
    [ -z "${DSTDB_INIT_DIR}" ] && export DSTDB_INIT_DIR=${DSTDB_PROFILE_DICT[init_dir]}
    if [ -z "${DSTDB_INIT_DIR}" ]; then export DSTDB_INIT_DIR=$DSTDB_GRP; fi

    case "${DSTDB_GRP,,}" in
        bigquery)
            mkdir -p ${CFG_DIR}/gbq/dst
            echo $GBQ_DST_SECRET | base64 -d | gunzip > ${CFG_DIR}/gbq/dst/secret.json
            export GBQ_DST_PROJECT_ID=$(jq -r ".project_id" ${CFG_DIR}/gbq/dst/secret.json) 
            export GBQ_DST_SERVICE_EMAIL=$(jq -r ".client_email" ${CFG_DIR}/gbq/dst/secret.json)

            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=${DSTDB_PROFILE_DICT[schema]}
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
            ;;
        snowflake)

            DSTDB_HOST="${SNOW_DST_ENDPOINT}" 
            DSTDB_PORT="${SNOW_DST_PORT:-443}" 
            DSTDB_ARC_USER="${SNOW_DST_ID}" 
            DSTDB_ARC_PW="${SNOW_DST_SECRET}"                 

            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=${DSTDB_PROFILE_DICT[schema]}
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
            ;;
        informix)
            # HACK: for Informix, schema is same as the user name
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA="${DSTDB_ARC_USER}"
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
        ;;
        db2)
            # HACK: for Informix, schema is same as the user name
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA="${DSTDB_ARC_USER^^}"
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA^^}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER^^}
        ;;
        oracle)
            # HACK: for Oracle, comma schema is always blank
            export DSTDB_ARC_USER="c##${DSTDB_ARC_USER}"
            export DSTDB_SCHEMA="${DSTDB_ARC_USER^^}"
            export DSTDB_COMMA_SCHEMA=""
            export DSTDB_DB=""
        ;;
        *)
            [ -z "${DSTDB_SCHEMA}" ] && export DSTDB_SCHEMA=${DSTDB_PROFILE_DICT[schema]}
            [ ! -z "${DSTDB_SCHEMA}" ] && export DSTDB_COMMA_SCHEMA=",${DSTDB_SCHEMA}"
            [ -z "${DSTDB_DB}" ] && export DSTDB_DB=${DSTDB_ARC_USER}
        ;; 
    esac

    [ -z "${DSTDB_BENCHBASE_TYPE}" ] && export DSTDB_BENCHBASE_TYPE=${DSTDB_PROFILE_DICT[benchbase_type]}
    [ -z "${DSTDB_JDBC_ISOLATION}" ] && export DSTDB_JDBC_ISOLATION=${DSTDB_PROFILE_DICT[benchbase_txn_isolation]}

    echo "Destination DB Config:"
    set | grep "^DSTDB_" | grep -v "_old="

    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            DSTDB_HOST=${DSTDB_HOST_old}
            DSTDB_DIR=${DSTDB_DIR_old}   
            DSTDB_TYPE=${DSTDB_TYPE_old}   
            DSTDB_GRP=${DSTDB_GRP_old}
            DSTDB_PORT=${DSTDB_PORT_old}               
            DSTDB_ROOT=${DSTDB_ROOT_old}               
        fi
    fi
done
}
