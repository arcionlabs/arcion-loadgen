#!/usr/bin/env bash

PAUSE_SECONDS=5
CFGDIR=$1

if [ -z "${CFGDIR}" ]; then
    . /tmp/ini_menu.sh
else
    . $CFGDIR/ini_menu.sh
fi

files=(src.yaml \
    dst.yaml \
    src_extract.yaml \
    src_filter.yaml \
    dst_mapper.yaml \
    dst_applier.yaml \
    src.init.root.* \
    src.init.user.* \
    dst.init.root.* \
    dst.init.user.* \
    )

echo $CFG_DIR looking for ${files[*]}
pushd $CFG_DIR >/dev/null

for pattern in "${files[@]}"; do
    # case insensitive name
    # exclude anyting that ends with .log
    for f in $( find -iname "$pattern" \( ! -iname "*.log" \) -type f); do
        clear
        echo ---- $f -----
        pygmentize $f
        echo ---- $f -----
        read -t $PAUSE_SECONDS -s -p "Waiting for $PAUSE_SECONDS seconds or press key to continue."
    done
done
popd >/dev/null