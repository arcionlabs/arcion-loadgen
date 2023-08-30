#!/usr/bin/env bash 

. ${SCRIPTS_DIR}/lib/map_csv.sh
. ${SCRIPTS_DIR}/lib/nine_char_id.sh

heredoc_file() {
    # heredoc on a file
    eval "$( echo -e '#!/usr/bin/env bash\ncat << EOF_EOF_EOF' | cat - $1 <(echo -e '\nEOF_EOF_EOF') )"    
    # TODO: a way to capture error code from here
}

copy_config() {
            filename=$(basename $f)
            # print info if over writing
            if [ -f $DST/$filename ]; then
                echo "override/merge $f -> $DST/$filename"
            fi 
            # perform the actual copy
            local suffix=$( echo $f | awk -F. '{print $NF}' )
            if [ "$suffix" = "sh" ]; then 
                # DEBUG: echo "cp $f $DST/$filename"
                cp ${f} $DST/$filename 
            elif [ "$suffix" = "yaml" ]; then 
                # DEBUG: echo "heredoc_file ${f} > $DST/$filename"
                export EPOC_10TH_SEC="$(epoch_10th_sec)"
                TMPFILE=$(mktemp)
                $SCRIPTS_DIR/lib/merge_arcion_yaml.py files $DST/$filename $f > $TMPFILE
                if [ "$?" = "0" ]; then
                    mv $TMPFILE $DST/$filename                
                else
                    heredoc_file ${f} > $DST/$filename
                fi 
            else
                # DEBUG: echo "heredoc_file ${f} > $DST/$filename"
                EPOC_10TH_SEC="$(epoch_10th_sec)" heredoc_file ${f} > $DST/$filename
            fi        
}

copy_hier_as_flat() {
    local SRC=${1:-"./"}
    local PREFIX=$2
    local DST=${3:-/tmp/$(basename $(realpath $SRC))}
    #DEBUG echo "SRC=$SRC DST=$DST PREFIX=$PREFIX"
    [ ! -d "${DST}" ] && mkdir -p ${DST}
    dir=""  # intially
    for d in $( echo $SRC |  tr "/" "\n" ); do
        # DEBUG: echo "${dir}${d}"
        dir="${dir}${d}"
        if [ ! -d "${dir}" ]; then continue; fi
        for f in $( find $dir -maxdepth 1 -type f -name $PREFIX\*.yaml -o -name $PREFIX\*.sh -o -name $PREFIX\*.sql -o -name $PREFIX\*.js  -o -name $PREFIX\*.xml ); do
            copy_config
        done
        if [ -d "$dir/init.d" ]; then
            for f in $( find $dir/init.d -maxdepth 1 -type f -name $PREFIX\*.yaml -o -name $PREFIX\*.sh -o -name $PREFIX\*.sql -o -name $PREFIX\*.js  -o -name $PREFIX\*.xml ); do
                copy_config
            done
        fi
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

    # copy from template (utils dir)
    # SRCDB_INIT_DIR is from profile
    pushd ${SCRIPTS_DIR}/utils >/dev/null
    copy_hier_as_flat ${SRCDB_INIT_DIR} src $CFG_DIR
    copy_hier_as_flat ${DSTDB_INIT_DIR} dst $CFG_DIR
    copy_hier_as_flat arcion       ""  $CFG_DIR
    copy_hier_as_flat benchbase/src sample $CFG_DIR/benchbase/src
    copy_hier_as_flat benchbase/dst sample $CFG_DIR/benchbase/dst
    popd >/dev/null

    # override template from the src and dst configs into a flat dir
    pushd ${SCRIPTS_DIR} >/dev/null
    copy_hier_as_flat $SRCDB_DIR src $CFG_DIR
    copy_hier_as_flat $DSTDB_DIR dst $CFG_DIR
    copy_hier_as_flat $SRCDB_DIR/benchbase/src sample $CFG_DIR/benchbase/src
    copy_hier_as_flat $DSTDB_DIR/benchbase/dst sample $CFG_DIR/benchbase/dst
    copy_hier_as_flat $METADATA_DIR meta $CFG_DIR
    popd >/dev/null

    # override the destination specific
    if [ -d $SRCDB_DIR/src_dst_map ]; then
        pushd $SRCDB_DIR/src_dst_map >/dev/null
        copy_hier_as_flat $DSTDB_GRP/$DSTDB_TYPE/ src $CFG_DIR
        popd >/dev/null
    fi

    # merge the filter yaml
    $SCRIPTS_DIR/lib/merge_arcion_yaml.py filter \
        --basedir $SCRIPTS_DIR/arcion/filter \
        $(echo ${arcion_filters} | tr ',' ' ' ) \
        > $CFG_DIR/src_filter.yaml

    # merge the applier / extractor yaml
    for configs in src_extractor dst_applier; do
        readarray -d '_' -t loc_config < <(printf '%s' "${configs}")
        loc=${loc_config[0]}
        config=${loc_config[1]}
        baseyaml="${CFG_DIR}/${loc}_${config}.yaml"
        # skip basefile does not exist
        if [ -f "${baseyaml}" ]; then
            TMPFILE=$(mktemp)
            $SCRIPTS_DIR/lib/merge_arcion_yaml.py app \
                --replmode "${REPL_TYPE}" \
                --config ${config} \
                --baseyaml ${baseyaml} \
                --basedir $SCRIPTS_DIR/app \
                $(echo ${arcion_filters} | tr ',' ' ' ) \
                > $TMPFILE
            if [ "$?" = "0" ]; then 
                diff ${baseyaml} $TMPFILE
                mv ${baseyaml} ${baseyaml}.old
                mv $TMPFILE ${baseyaml}
            fi
        fi
    done

    # done
    echo "Config at $CFG_DIR"
}

infer_dbdir() {
    local -n DB_PROFILE_DICT=${1}
    local DB_HOST=${2}

    if [ -z "${DB_HOST}" ]; then
        echo '$1 should be DB_HOST' >&2
        return 1
    fi

    # match on hostname
    if [ -d ${SCRIPTS_DIR}/${DB_HOST} ]; then
        echo "DB_DIR: $DB_HOST inferred from the exact hostname." >&2
        echo "$DB_HOST"
        return 0
    fi    
    # match on type
    if [ -d ${SCRIPTS_DIR}/${DB_PROFILE_DICT[type]} ]; then
        echo "DB_DIR: ${DB_PROFILE_DICT[type]} from type." >&2
        echo "${DB_PROFILE_DICT[type]}"
        return 0
    fi

    # match on group
    if [ -n "${DB_PROFILE_DICT[group]}" ]; then
        if [ -d ${SCRIPTS_DIR}/${DB_PROFILE_DICT[group]} ]; then
            echo "DB_DIR: ${DB_PROFILE_DICT[group]} from group." >&2
            echo "${DB_PROFILE_DICT[group]}"
            return 0
        fi
    fi

    # match on db_dir
    if [ -n "${DB_PROFILE_DICT[db_dir]}" ]; then
        if [ -d ${SCRIPTS_DIR}/${DB_PROFILE_DICT[db_dir]} ]; then
            echo "DB_DIR: ${DB_PROFILE_DICT[db_dir]} from db_dir." >&2
            echo "${DB_PROFILE_DICT[db_dir]}"
            return 0
        fi
    fi

    echo "DB_DIR was not specifed and could not infer from HOSTNAME." >&2
    return 1
}

