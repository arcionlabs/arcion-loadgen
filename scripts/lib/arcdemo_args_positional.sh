#!/usr/bin/env bash 

function arcdemo_positional() {

    banner here
    
    # set REPL_TYPE from command line
    if [ ! -z "$1" ]; then 
        export REPL_TYPE=$1; 
    fi

    # set from SRC URI command line
    if [ ! -z "$2" ]; then 
        uri_parser "$2"
        [ "${uri_schema}" ] && export SRCDB_TYPE=${uri_schema} 
        [ "${uri_user}" ] && export SRCDB_ARC_USER=${uri_user}
        [ "${uri_password}" ] && export SRCDB_ARC_PW=${uri_password}
        [ "${uri_host}" ] && export SRCDB_HOST=${uri_host}
        [ "${uri_port}" ] && export SRCDB_PORT=${uri_port}
        [ "${uri_path}" ] && export SRCDB_SUBDIR=${uri_path}
    fi

    # set from DST URL command line
    if [ ! -z "$3" ]; then
        uri_parser "$3"
        [ "${uri_schema}" ] && export DSTDB_TYPE=${uri_schema} 
        [ "${uri_user}" ] && export DSTDB_ARC_USER=${uri_user}
        [ "${uri_password}" ] && export DSTDB_ARC_PW=${uri_password}
        [ "${uri_host}" ] && export DSTDB_HOST=${uri_host}
        [ "${uri_port}" ] && export DSTDB_PORT=${uri_port}
        [ "${uri_path}" ] && export DSTDB_SUBDIR=${uri_path}
    fi

    export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
    export SRCDB_ARC_PW=${SRCDB_ARC_PW:-Passw0rd}

    export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
    export DSTDB_ARC_PW=${DSTDB_ARC_PW:-Passw0rd}

}