#!/usr/bin/env bash

# cat trace.log  | tracelog_general
tracelog_general () {
    awk '/General Config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,0)}' 
}

tracelog_src() { 
    awk '/Source connection config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'
}

tracelog_filter() {
    awk '/Filter[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'
}

tracelog_dst() { 
    awk '/Destination connection config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' 
}

tracelog_ext_snap() { 
    awk '/Extractor snapshot configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' 
}

tracelog_ext_realtime() {
    awk '/Extractor realtime configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' 
}

tracelog_applier_snap() {
    awk '/Applier snapshot configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'
}

tracelog_applier_realtime() {
    awk '/Applier realtime configuration[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}'
}

tracelog_dist() {
    awk '/Distribution config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{print substr($0,3)}' 
}

tracelog_metadata() {
    awk '/Metadata config[[:space:]]*:[[:space:]]*$/{flag=1;next} flag && /^[0-9]+/ {exit} flag{if ($1=="database"){print $1 ": " $2 }else{print substr($0,0)}}'
}

