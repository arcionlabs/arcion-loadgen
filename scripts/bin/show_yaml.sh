#!/usr/bin/env bash

CFGDIR=$1

if [ -z "${CFGDIR}" ]; then
    . /tmp/ini_menu.sh
else
    . $CFGDIR/ini_menu.sh
fi

if [ -z "$PAUSE_SECONDS" ]; then export PAUSE_SECONDS=1; fi

files=(src.yaml \
    dst.yaml \
    src_extractor.yaml \
    src_filter.yaml \
    dst_mapper.yaml \
    dst_applier.yaml \
    general.yaml \
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
        file_extension="${f##*.}"
        echo ---- $f -----
        cat $f |  sed \
            -e 's/\(username\:\).*$/\1 ********/i' \
            -e 's/\(password\:\).*$/\1 ********/i' \
            -e 's/\(access-key\:\).*$/\1 ********/i'  \
            -e 's/\(secret-key\:\).*$/\1 ********/i'  \
            -e 's/\(key-id\:\).*$/\1 ********/i' \
            | pygmentize -l ${file_extension}
        echo ---- $f -----
        read -t $PAUSE_SECONDS -s -p "Waiting for $PAUSE_SECONDS seconds or press key to continue."
    done
done
clear
figlet -tc "${REPL_TYPE^^}"
figlet -tc "${SRCDB_TYPE^^} -> ${DSTDB_TYPE^^}"
figlet -tc "${arcion_filters}"
popd >/dev/null