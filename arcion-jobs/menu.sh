#!/usr/bin/env bash

ARCION_HOME=${ARCION_HOME:-/arcion/replicant-cli}
JOB_HOME=${JOB_HOME:-/jobs}

# subsutite env var in YAML with the actual
copy_yaml() {
    local JOB=$1
    export YAML_DIR=/tmp/$JOB.$$
    mkdir -p $YAML_DIR
    for f in $JOB_HOME/$JOB/*; do 
        echo envsubst $f
        cat $f | envsubst > $YAML_DIR/$(basename $f) 
    done
}

arcion_full() {
    export LOG=${1:-full}.$$
    if [ -d ${ARCION_HOME}/replicant-cli ]; then pushd $ARCION_HOME/replicant-cli; else pushd $ARCION_HOME; fi
    ./bin/replicant full ${YAML_DIR}/src_1.yaml ${YAML_DIR}/dst_1.yaml \
    --filter ${YAML_DIR}/src_1_filter.yaml \
    --extractor ${YAML_DIR}/src_1_extractor.yaml \
    --applier ${YAML_DIR}/dst_1_applier.yaml \
    --replace-existing \
    --overwrite \
    --id $LOG
    popd
}

arcion_snapshot() {
    export LOG=${1:-snap}.$$
    if [ -d ${ARCION_HOME}/replicant-cli ]; then pushd $ARCION_HOME/replicant-cli; else pushd $ARCION_HOME; fi
    ./bin/replicant snapshot ${YAML_DIR}/src_1.yaml ${YAML_DIR}/dst_1.yaml \
    --filter ${YAML_DIR}/src_1_filter.yaml \
    --extractor ${YAML_DIR}/src_1_extractor.yaml \
    --applier ${YAML_DIR}/dst_1_applier.yaml \
    --replace-existing \
    --overwrite \
    --id $LOG
    popd
}

select_src() {
    PS3='Please enter the source: '
    options=( $(find * -maxdepth 0 -type d) )
    select SRCDB_TYPE in "${options[@]}"; do
        if [ -d "$SRCDB_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_TYPE
}

select_dst() {
    PS3='Please enter the target: '
    options=( $(cd $SRCDB_TYPE; find * -maxdepth 0 -type d; cd ..) )
    select DSTDB_TYPE in "${options[@]}"; do
        if [ -d "$SRCDB_TYPE/$DSTDB_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_TYPE
}

select_replication() {
    PS3='Please enter the replication type: '
    options=( "full" "snapshot" )
    select REPL_TYPE in "${options[@]}"; do
        if [ ! -z "$REPL_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export REPL_TYPE
}

# set source and destination
if [ -z "${SRCDB_TYPE}" ]; then select_src; fi
if [ -z "${DSTDB_TYPE}" ]; then select_dst; fi
echo ${SRCDB_TYPE} ${DSTDB_TYPE}

# set replication type
if [ -z "${REPL_TYPE}" ]; then select_replication; fi
echo ${REPL_TYPE}

# set config file
copy_yaml ${SRCDB_TYPE}/${DSTDB_TYPE}
echo ${YAML_DIR}

# run the replication
case ${REPL_TYPE} in
  full)
    arcion_full
    echo $LOG
    ;;
  snapshot)
    arcion_snapshot
    echo $LOG
    ;;
  *)
    echo "REPL_TYPE: ${REPL_TYPE} unsupported"
    ;;
esac
