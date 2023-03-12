#!/usr/bin/env bash

JSQSH_CSV="-n -v headers=false -v footers=false"

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/lib/jdbc_cli.sh


dump_table_test() {
    local LOC="${1:-SRC}"        # SRC|DST
    local TABLE_NAME="${2:-usertable}"    # usertable|sbtest1
    local -n cols=$3
    local REMOVE_COLS=${3:-ts2}

    for x in ${cols[@]}; do echo $x; done
}

# dump the tables common to both src and dst
dump_tables() {
    list_tables src | awk -F',' '$1=/TABLE/ {print $2}' | sort > /tmp/validate.src_tables.$$
    list_tables dst | awk -F',' '$1=/TABLE/ {print $2}' | sort > /tmp/validate.dst_tables.$$
    for t in $( comm -12 /tmp/validate.src_tables.$$ /tmp/validate.dst_tables.$$ ); do
        echo "$t: retrieving columns"
        list_columns src $t | sort > /tmp/validate.src_$t.$$ 
        list_columns dst $t | sort > /tmp/validate.dst_$t.$$
        # save the common columns between source and target
        common_cols=( $(comm -12 /tmp/validate.src_$t.$$ /tmp/validate.dst_$t.$$ |  paste -s -d,) )
        echo "$t: ${common_cols} are common"
        echo "$t: retrieving the data from the tables"
        dump_table src $t "$common_cols"
        dump_table dst $t "$common_cols"
        # diff the two filesA
        echo "$t: running diff on the dataset"
        echo "ls ${CFG_DIR}/*.${t}.tsv | xargs diff > ${CFG_DIR}/${t}.diff"
        ls ${CFG_DIR}/*.${t}.tsv | xargs diff > ${CFG_DIR}/${t}.diff
        if [ "$?" == "0" ]; then
            echo "$t: src and dst match"
        else
            echo "$t: display the first 10 diff from ${CFG_DIR}/${t}.diff"
            head -n 10 ${CFG_DIR}/${t}.diff
        fi
    done
    rm /tmp/validate.*.$$
}

sourced="0"
if [ -n "$ZSH_VERSION" ]; then 
case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
[ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
(return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames.
# Detects `sh` and `dash`; add additional shell filenames as needed.
case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
fi

if [ "$sourced" = "0" ]; then
    dump_tables
    echo "These tables are not same"
    find ${CFG_DIR} -type f -size +0 -name '*.diff'
fi