#!/usr/bin/env bash 

function latest_hostname() {
    local HOSTNAME=$1
    local ROLE=${2:-src}    # SRC|DST src is usally 1 or src, dst is usally 2 or dst

    if [ -z "$HOSTNAME" ]; then 
        return 
    fi

    # get IPs
    # -W wait max 1 sec (good for local lookup)
    # /has address/ show just ipv4
    x_array=( $(host -W 1 ${HOSTNAME} | awk '/has address/ {print $NF}') )
    echo "$HOSTNAME has following IPs: ${x_array[*]}" >&2

    if [ -z "${x_array}" ]; then 
        # not found, try adding role
        HOSTNAME=${HOSTNAME}-${ROLE,,}
        x_array=( $(host -W 1 ${HOSTNAME} | awk '/has address/ {print $NF}') )
        echo "$HOSTNAME has following IPs: ${x_array[*]}" >&2

        if [ -z "${x_array}" ]; then 
            echo "not found.  using $HOSTNAME" >&2
            echo ${1} 
        fi
    fi

    # the name is expected to be three segments separted by -
    # mysql-version-instance
    # take the hightest version with 
    #   latest is always the highest if exists
    # the source is lowest instance
    # the target is the highest instance
    if (( ${#x_array[@]} > 0 )); then
        if [ "${ROLE^^}" = "SRC" ]; then
            HOSTNAMES_ARRAY=( $( nmap -sn -oG - $(echo ${x_array[*]}) \
                | awk -F'[()]' '/Up$/ {print $(NF-1)}' \
                | awk -F'.' '{print $1}' \
                | sort -t '-' -k2,2r -k3,3 \
                ) )
        else
            HOSTNAMES_ARRAY=( $( nmap -sn -oG - $(echo ${x_array[*]}) \
                | awk -F'[()]' '/Up$/ {print $(NF-1)}' \
                | awk -F'.' '{print $1}' \
                | sort -t '-' -k2,2r -k3,3r \
                ) )
        fi

        echo "$HOSTNAME has following name(s): ${HOSTNAMES_ARRAY[*]}" >&2
        echo ${HOSTNAMES_ARRAY[0]}
    fi
}

function arcdemo_positional() {
    
    # set REPL_TYPE from command line
    if [ -n "$1" ]; then 
        export REPL_TYPE=$1; 
        case $REPL_TYPE in
            snapshot|real-time|delta-snapshot|full) 
                ;;
            *) echo "Error: replication type $REPL_TYPE must be snapshot|real-time|delta-snapshot|full" >&2  
               exit 1
                ;;
        esac
    fi

    # set from SRC URI command line
    if [ -n "$2" ]; then 
        unset uri; declare -A uri;  
        unset uri_path; declare -a uri_path;  
        unset uri_query; declare -A uri_query;  
        uri_parser uri uri_path uri_query "$2"
        if [ "$?" = 0 ]; then
            [ "${uri[scheme]}" ] && export SRCDB_TYPE= "${uri[scheme]}" 
            [ "${uri[username]}" ] && export SRCDB_ARC_USER="${uri[username]}"
            [ "${uri[password]}" ] && export SRCDB_ARC_PW="${uri[password]}"
            [ "${uri[hostname]}" ] && export SRCDB_SHORTNAME="${uri[hostname]}"
            [ "${uri[port]}" ] && export SRCDB_PORT="${uri[port]}"
            [ "${uri[path]}" ] && export SRCDB_DIR="${uri_path[0]}"
            [ "${uri_query[dbs]}" ] && export SRCDB_DB="${uri_query[dbs]}"
        fi
    fi

    # set from DST URL command line
    if [ -n "$3" ]; then
        unset uri; declare -A uri;  
        unset uri_path; declare -a uri_path;  
        unset uri_query; declare -a uri_query;  
        uri_parser uri uri_path uri_query "$3"
        if [ "$?" = 0 ]; then
            [ "${uri[scheme]}" ] && export DSTDB_TYPE= "${uri[scheme]}" 
            [ "${uri[username]}" ] && export DSTDB_ARC_USER="${uri[username]}"
            [ "${uri[password]}" ] && export DSTDB_ARC_PW="${uri[password]}"
            [ "${uri[hostname]}" ] && export DSTDB_SHORTNAME="${uri[hostname]}"
            [ "${uri[port]}" ] && export DSTDB_PORT="${uri[port]}"
            [ "${uri[path]}" ] && export DSTDB_DIR="${uri_path[0]}"
            [ "${uri_query[dbs]}" ] && export DSTDB_DB="${uri_query[dbs]}"
        fi
    fi

    # grab filters CSV
    if [ -n "$4" ]; then
        export arcion_filters="${4}"
    else
        export arcion_filters="${workload_modules_bb}"
    fi
}

# set variables from envvar
# $1=name of variable to set
# $2=name of env variable
set_var_from_envvar() {
    local varname=$1
    local envvar=$2
    printf -v "$varname" '%s' ${!envvar}
}
set_var_from_value() {
    local varname=$1
    local val=$2
    printf -v "$varname" '%s' ${val}
}

function set_default_host_user() {
    local env_map
    local env_value
    local x
    
    # map variables from profile's env_var column
    env_map=( ${SRCDB_PROFILE_DICT["env_map"]} )
    for x in ${env_map[@]}; do
        readarray -d'=' -t VAR_VAR < <(printf '%s' "$x")
        declare -p VAR_VAR
        if (( ${#VAR_VAR[@]} == 2 )); then
            set_var_from_envvar SRC${VAR_VAR[0]} ${VAR_VAR[1]}
        else
            echo "$x: ignoring"
        fi
        # show the value of val
        y=SRC${VAR_VAR[0]}
        echo $y=${!y}
    done

    # map variables from profile's env_val column
    env_value=( ${SRCDB_PROFILE_DICT["env_value"]} )
    for x in ${env_value[@]}; do
        readarray -d'=' -t VAR_VALUE < <(printf '%s' "$x")
        declare -p VAR_VALUE
        if (( ${#VAR_VALUE[@]} == 2 )); then
        set_var_from_value SRC${VAR_VALUE[0]} ${VAR_VALUE[1]}
        else
        echo "$x: ignoring"
        fi
        # show the value of val
        y=SRC${VAR_VALUE[0]}
        echo $y=${!y}
    done

    # map variables from profile's env_var column
    env_map=( ${DSTDB_PROFILE_DICT["env_map"]} )
    for x in ${env_map[@]}; do
        readarray -d'=' -t VAR_VAR < <(printf '%s' "$x")
        declare -p VAR_VAR
        if (( ${#VAR_VAR[@]} == 2 )); then
        set_var_from_envvar DST${VAR_VAR[0]} ${VAR_VAR[1]}
        else
        echo "$x: ignoring"
        fi
        # show the value of val
        y=DST${VAR_VAR[0]}
        echo $y=${!y}
    done

    # map variables from profile's env_val column
    env_value=( ${DSTDB_PROFILE_DICT["env_value"]} )
    for x in ${env_value[@]}; do
        readarray -d'=' -t VAR_VALUE < <(printf '%s' "$x")
        declare -p VAR_VALUE
        if (( ${#VAR_VALUE[@]} == 2 )); then
        set_var_from_value DST${VAR_VALUE[0]} ${VAR_VALUE[1]}
        else
        echo "$x: ignoring"
        fi
        # show the value of val
        y=DST${VAR_VALUE[0]}
        echo $y=${!y}
    done

    # incase of multiple names, take the latest
    if [ -z "${SRCDB_HOST}" ]; then SRCDB_HOST=$(latest_hostname "${SRCDB_SHORTNAME}" "src"); fi
    if [ -z "${DSTDB_HOST}" ]; then DSTDB_HOST=$(latest_hostname "${DSTDB_SHORTNAME}" "dst"); fi

    if [ "$workload_size_factor" = "1" ]; then
        export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
        export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
    else
        export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc${workload_size_factor}}
        export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst${workload_size_factor}}
    fi

    export SRCDB_ARC_PW=${SRCDB_ARC_PW:-Passw0rd}
    export DSTDB_ARC_PW=${DSTDB_ARC_PW:-Passw0rd}
}
