#!/usr/bin/env bash 

function latest_hostname() {
    local HOSTNAME=$1
    local ROLE=${2:-SRC}    # SRC|DST src is usally 1 or src, dst is usally 2 or dst
    # get IPs
    # -W wait max 1 sec (good for local lookup)
    # /has address/ show just ipv4
    x_array=( $(host -W 1 ${HOSTNAME} | awk '/has address/ {print $NF}') )
    echo "$HOSTNAME has following IPs: ${x_array[*]}" >&2

    if [ -z "${x_array}" ]; then 
        # not found, return the input as is
        echo "not found.  using $HOSTNAME" >&2
        echo ${1} 

    else 
        # the name is expected to be three segments separted by -
        # mysql-version-instance
        # take the hightest version with 
        #   latest is always the highest if exists
        # the source is lowest instance
        # the target is the highest instance

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
    if [ ! -z "$1" ]; then 
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
    if [ ! -z "$2" ]; then 
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
    if [ ! -z "$3" ]; then
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

    # incase of multiple names, take the latest
    SRCDB_HOST=$(latest_hostname ${SRCDB_SHORTNAME} src)
    DSTDB_HOST=$(latest_hostname ${DSTDB_SHORTNAME} dst)

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