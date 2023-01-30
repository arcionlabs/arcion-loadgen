
show live hosts in a submet

nmap -sP 172.18.0.0/24

find_hosts() {
    if [ ! -f /tmp/names.$$.txt ]; then
        ip=$( hostname -i | awk -F'.' '{print $1"."$2"."$3"."0"/24"}' )
        nmap -sn -oG /tmp/names.$$.txt $ip >/dev/null
    fi
    cat /tmp/names.$$.txt | grep 'arcnet' | awk -F'[ ()]' '{print $4}'
}

ask_src_host() {
    PS3='Please enter the SOURCE host: '
    options=( $(find_hosts) )
    select SRCDB_HOST in "${options[@]}"; do
        if [ ! -z "$SRCDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_HOST
}

ask_dst_host() {
    PS3='Please enter the DESTINATION host: '
    options=( $(find_hosts) )
    select DSTDB_HOST in "${options[@]}"; do
        if [ ! -z "$DSTDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_HOST
}

