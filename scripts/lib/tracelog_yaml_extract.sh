#!/usr/bin/env bash

# for testing
#   . tracelog_yaml_extract.sh
#   cd <dir that has trace.log>
#   tracelog_save_as_yaml
#   vi yaml/*
#
# \b word boundary
# ^[:space:]] not space

# cat trace.log  | tracelog_general
tracelog_general () {
    awk '/General Config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,0)}' | \
        sed -e 's/\(\b.+\)[^[:space:]]\(\:\\)\([^[:space:]]\)\(.*\)$/\1 \2\3/'
    # key : value -> key: value    
}

tracelog_src() { 
    awk '/Source connection config[[:space:]]*:[[:space:]].*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' | \
        sed -e 's/\b\(password\:\) \(\**\)/\1 "\2"/g' -e 's/\b\(accessKey\:\) \(\**\)/\1 "\2"/g'  -e 's/\b\(secretKey\:\) \(\**\)/\1 "\2"/g' -e 's/\b\(key\:\) \(\**\)/\1 "\2"/g' \
        -e 's/\b\(sqlJobsPassword:\) \(\**\)/\1 "\2"/g'
    # /Source connection config[[:space:]]*:[[:space:]]*$/ matches all except sybase     
}

tracelog_filter() {
    awk '/Filter[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'
}

tracelog_dst() { 
    awk '/Destination connection config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' | \
        sed -e 's/\([*]\+\)/"\1"/g' \
            -e 's/\(\barchive-type\)$/\1\:/' |
         awk -v q="'" 'substr($1,length($1),1) != ":" {print q $0 q ":"; next} {print $0}'

#        a line without lieading : take the wohole thing as key         
#        -e 's/\b\(password\:\) \(\**\)/\1 "\2"/g' \
#        -e 's/\b\(accessKey\:\) \(\**\)/\1 "\2"/g'  \
#        -e 's/\b\(secretKey\:\) \(\**\)/\1 "\2"/g' \
#        -e 's/\b\(key\:\) \(\**\)/\1 "\2"/g' \

}

tracelog_ext_snap() { 
    awk '/Extractor snapshot configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' | \
        sed -e 's/\(\b.*\:\)\([^[:space:]]\)\(.*\)$/\1 \2\3/'
    # key:value -> key: value
}

tracelog_ext_realtime() {
    awk '/Extractor realtime configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'  | \
        sed -e 's/\(\b.*\:\)\([^[:space:]]\)\(.*\)$/\1 \2\3/'
    # key:value -> key: value
}

tracelog_applier_snap() {
    awk '/Applier snapshot configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' | \
        sed -e 's/\(\b.*\:\)\([^[:space:]]\)\(.*\)$/\1 \2\3/' | \
        awk -F':' -v q="'" 'NF==1 {print q $0 q ":"; next} {print $0}' | \
        awk -F':' '$1=="bulk-data-location" && $2==" null" {printf "%s:\n",$1; next} {print $0}'
    # key:value -> key: value
    # key$ -> key: key only line without :
    # bulk-data-location: null -> bulk-data-location:
}

tracelog_applier_realtime() {
    awk '/Applier realtime configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' | \
        sed -e 's/\(\b.*\:\)\([^[:space:]]\)\(.*\)$/\1 \2\3/'
    # key:value -> key: value
}

tracelog_dist() {
    awk '/Distribution config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' 
}

tracelog_metadata() {
    awk '/Metadata config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{if ($1=="database"){print $1 ": " $2 }else{print substr($0,0)}}'
}

tracelog_save_as_yaml() {
    local LOG_DIR=${1:-"."}
    
    # scrape yaml
    mkdir -p ${LOG_DIR}/yaml
    cat ${LOG_DIR}/trace.log | tracelog_general > ${LOG_DIR}/yaml/general.yaml
    cat ${LOG_DIR}/trace.log | tracelog_src > ${LOG_DIR}/yaml/src.yaml
    cat ${LOG_DIR}/trace.log | tracelog_filter > ${LOG_DIR}/yaml/filter.yaml
    cat ${LOG_DIR}/trace.log | tracelog_dst > ${LOG_DIR}/yaml/dst.yaml
    cat ${LOG_DIR}/trace.log | tracelog_ext_snap > ${LOG_DIR}/yaml/ext_snap.yaml
    cat ${LOG_DIR}/trace.log | tracelog_ext_realtime > ${LOG_DIR}/yaml/ext_realtime.yaml
    cat ${LOG_DIR}/trace.log | tracelog_applier_snap > ${LOG_DIR}/yaml/app_snap.yaml
    cat ${LOG_DIR}/trace.log | tracelog_applier_realtime > ${LOG_DIR}/yaml/app_realtime.yaml
    cat ${LOG_DIR}/trace.log | tracelog_dist > ${LOG_DIR}/yaml/dist.yaml
    cat ${LOG_DIR}/trace.log | tracelog_metadata > ${LOG_DIR}/yaml/metadata.yaml

    # convert yaml to json
    for y in $(find ${LOG_DIR}/yaml -name "*.yaml" -printf "%f\n"); do
        echo $y
        f_nosuffix=${y%.*}   # remove suffix starting with "."
        echo $f_nosuffix
        yq . ${LOG_DIR}/yaml/$y > ${LOG_DIR}/yaml/$f_nosuffix.json
    done
}