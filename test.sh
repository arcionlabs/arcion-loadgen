#!/usr/bin/env bash 

# $1 = ratio
# $2 = default if ratio in 0 or space
parse_ratio() {
    c1=$( echo $1 | cut -d: -f1 )
    if [ "${c1}" = "0" ] || [ -z "${c1}" ]; then c1=${2}; fi
    c2=$( echo $1 | cut -d: -f2 )
    if [ "${c2}" = "0" ] || [ -z "${c2}" ]; then c2=${2}; fi
} 
parse_ratio "$1" "$2"
echo "$c1" "$c2"