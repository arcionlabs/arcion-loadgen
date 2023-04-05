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
        uri_parser uri uri_path uri_query "$2"
        if [ "$?" = 0 ]; then
            [ "${uri[scheme]}" ] && export SRCDB_TYPE= "${uri[scheme]}" 
            [ "${uri[username]}" ] && export SRCDB_ARC_USER="${uri[username]}"
            [ "${uri[password]}" ] && export SRCDB_ARC_PW="${uri[password]}"
            [ "${uri[hostname]}" ] && export SRCDB_HOST="${uri[hostname]}"
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
            [ "${uri[hostname]}" ] && export DSTDB_HOST="${uri[hostname]}"
            [ "${uri[port]}" ] && export DSTDB_PORT="${uri[port]}"
            [ "${uri[path]}" ] && export DSTDB_DIR="${uri_path[0]}"
            [ "${uri_query[dbs]}" ] && export DSTDB_DB="${uri_query[dbs]}"
        fi
    fi

    export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
    export SRCDB_ARC_PW=${SRCDB_ARC_PW:-Passw0rd}

    export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
    export DSTDB_ARC_PW=${DSTDB_ARC_PW:-Passw0rd}
}