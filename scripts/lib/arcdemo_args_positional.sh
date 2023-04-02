#!/usr/bin/env bash 

function arcdemo_positional() {
    
    # set REPL_TYPE from command line
    if [ ! -z "$1" ]; then 
        export REPL_TYPE=$1; 
    fi

    # set from SRC URI command line
    if [ ! -z "$2" ]; then 
        unset uri; declare -A uri;  
        unset uri_path; declare -a uri_path;  
        unset uri_query; declare -a uri_query;  
        uri_parser uri uri_path uri+query "$2"
        if [ "$?" = 0 ]; then
            [ "${uri[scheme]}" ] && export SRCDB_TYPE= "${uri[scheme]}" 
            [ "${uri[username]}" ] && export SRCDB_ARC_USER="${uri[username]}"
            [ "${uri[password]}" ] && export SRCDB_ARC_PW="${uri[password]}"
            [ "${uri[hostname]}" ] && export SRCDB_HOST="${uri[hostname]}"
            [ "${uri[port]}" ] && export SRCDB_PORT="${uri[port]}"
            [ "${uri[path]}" ] && export SRCDB_SUBDIR="${uri[path]}"
            [ "${uri_path[0]}" ] && export SRCDB_DB="${uri_path[0]}"
        fi
    fi

    # set from DST URL command line
    if [ ! -z "$3" ]; then
        unset uri; declare -A uri;  
        unset uri_path; declare -a uri_path;  
        unset uri_query; declare -a uri_query;  
        uri_parser uri uri_path uri+query "$3"
        if [ "$?" = 0 ]; then
            [ "${uri[scheme]}" ] && export DSTDB_TYPE= "${uri[scheme]}" 
            [ "${uri[username]}" ] && export DSTDB_ARC_USER="${uri[username]}"
            [ "${uri[password]}" ] && export DSTDB_ARC_PW="${uri[password]}"
            [ "${uri[hostname]}" ] && export DSTDB_HOST="${uri[hostname]}"
            [ "${uri[port]}" ] && export DSTDB_PORT="${uri[port]}"
            [ "${uri[path]}" ] && export DSTDB_SUBDIR="${uri[path]}"
            [ "${uri_path[0]}" ] && export DSTDB_DB="${uri_path[0]}"
        fi
    fi

    export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
    export SRCDB_ARC_PW=${SRCDB_ARC_PW:-Passw0rd}
    export SRCDB_DB=${SRCDB_DB:-${SRCDB_ARC_USER}}

    export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
    export DSTDB_ARC_PW=${DSTDB_ARC_PW:-Passw0rd}
    export DSTDB_DB=${DSTDB_DB:-${DSTDB_ARC_USER}}
}