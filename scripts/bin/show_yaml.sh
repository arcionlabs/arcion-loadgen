#!/usr/bin/env bash

CFGDIR=$1

if [ -z "${CFGDIR}" ]; then
    . /tmp/ini_menu.sh
else
    . $CFGDIR/ini_menu.sh
fi

files=(src.yaml dst.yaml src_extract.yaml src_filter.yaml src_mapper.yaml dst_applier.yaml)

echo $CFG_DIR

for f in "${files[@]}"; do
    yaml=$CFG_DIR/$f
    if [ -f "$yaml" ]; then
        clear
        echo ---- $f -----
        pygmentize $yaml
        echo ---- $f -----
        read -t 10 -s -p "Waiting for 10 seconds or press key to continue"
    fi
done