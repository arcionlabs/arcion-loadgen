#!/usr/bin/env bash 

copy_hier_as_flat() {
    local SRC=${1:-"./"}
    local PREFIX=$2
    local DST=${3:-/tmp/$(basename $(realpath $SRC))}
    [ ! -d "${DST}" ] && mkdir -p ${DST}
    dir=""
    for d in $( echo $SRC |  tr "/" "\n" ); do
        echo "*${d}"
        dir="${dir}${d}"
        if [ ! -d "${dir}" ]; then continue; fi
        for f in $( find $dir -maxdepth 1 -type f -name $PREFIX\*.yaml -o -name $PREFIX\*.sh -o -name $PREFIX\*.sql -o -name $PREFIX\*.js  -o -name $PREFIX\*.xml ); do
            filename=$(basename $f)
            if [ -f $DST/$filename ]; then
                echo override $f $DST/$filename
            fi 
            local suffix=$( echo $f | awk -F. '{print $NF}' )
            if [ "$suffix" = "sh" ]; then 
                echo cp $f $DST/$filename
                cp ${f} $DST/$filename 
            else
                echo "cat "${f}" | PID=$$ envsubst > $DST/$filename"
                cat "${f}" | PID=$$ envsubst > $DST/$filename
            fi    
        done
        dir="${dir}/"
    done
}

copy_yaml() {
    local SRCDB_DIR="$1"
    local SRCDB_GRP="$2"
    local SRCDB_TYPE="$3"    
    local DSTDB_DIR="$4"
    local DSTDB_GRP="$5"
    local DSTDB_TYPE="$6"
    local PID

    [ -z "$SRCDB_DIR" ] && echo "copy_yaml: SRCDB_DIR is blank" >&2
    [ -z "$SRCDB_GRP" ] && echo "copy_yaml: SRCDB_GRP is blank" >&2
    [ -z "$SRCDB_TYPE" ] && echo "copy_yaml: SRCDB_TYPE is blank" >&2
    [ -z "$DSTDB_DIR" ] && echo "copy_yaml: DSTDB_DIR is blank" >&2
    [ -z "$DSTDB_GRP" ] && echo "copy_yaml: DSTDB_GRP is blank" >&2
    [ -z "$DSTDB_TYPE" ] && echo "copy_yaml: DSTDB_TYPE is blank" >&2

    # copy from template
    pushd ${SCRIPTS_DIR}/utils
    copy_hier_as_flat ${SRCDB_GRP} src $CFG_DIR
    copy_hier_as_flat ${DSTDB_GRP} dst $CFG_DIR
    copy_hier_as_flat benchbase sample $CFG_DIR/benchbase
    popd

    # override template from the src and dst configs into a flat dir
    pushd ${SCRIPTS_DIR}
    copy_hier_as_flat $SRCDB_DIR src $CFG_DIR
    copy_hier_as_flat $DSTDB_DIR dst $CFG_DIR
    copy_hier_as_flat $METADATA_DIR meta $CFG_DIR
    copy_hier_as_flat benchbase sample $CFG_DIR/benchbase
    popd

    # override the destination specific
    if [ -d $SRCDB_DIR/src_dst_map ]; then
        pushd $SRCDB_DIR/src_dst_map
        copy_hier_as_flat $DSTDB_GRP/$DSTDB_TYPE/ src $CFG_DIR
        popd
    fi

    echo "Config at $CFG_DIR"
}

infer_dbdir() {
    local DB_HOST=${1}
    local DB_DIR=${2}
    if [ -z "${DB_HOST}" ]; then
        echo '$1 should be DB_HOST' >&2
        return 1
    fi
    if [ -z "${DB_DIR}" ]; then 
        # infer srcdb type from the frist word of ${SRCDB_HOST}
        DB_DIR=$( echo ${DB_HOST} | awk -F'[-./0123456789]' '{print $1}' )
        if [ -d ${SCRIPTS_DIR}/${DB_DIR} ]; then
            echo "$DB_DIR inferred from hostname." >&2
            echo "$DB_DIR"
        else
            echo "DB_DIR was not specifed and could not infer from HOSTNAME." >&2
            return 1
        fi
    else
        echo ${DB_DIR}
    fi
}

