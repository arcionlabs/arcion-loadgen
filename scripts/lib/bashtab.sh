#!/usr/env/bin bash

#  echo ""
#  echo "COMP_WORDS : ${COMP_WORDS}"
#  echo "COMP_CWORD : ${COMP_CWORD}"
#  echo "COMP_WORDS[COMP_CWORD] : ${COMP_WORDS[COMP_CWORD]}"
#  echo "COMP_LINE : ${COMP_LINE}"
#  echo "COMP_POINT : ${COMP_POINT}"
#  echo "COMP_KEY : ${COMP_KEY}"
#  echo "COMP_TYPE : ${COMP_TYPE}"
#  echo "args : $@"
#  echo "reply : ${COMPREPLY[@]}"
_arcdemo.sh () {
    filename=/tmp/arcion/nmap/nmap.raw.txt
    setAvailHosts() {
        if [[ ! -d  /tmp/arcion/nmap ]]; then mkdir -p /tmp/arcion/nmap; fi
        readarray -d '.' -t hostipoctect <<< $(hostname -I) 
        subnet="${hostipoctect[0]}.${hostipoctect[1]}.${hostipoctect[2]}.0/24"
        subnet=$( hostname -I | awk -F'.' '{print $1 "." $2 "." $3 "." 0 "/24"}' )
            # don't spend more than 2 sec
            nmap -sn -oG /tmp/arcion/nmap/nmap.raw.txt $subnet |  >/dev/null
    }

    COMPREPLY=()

    if [[ -f ${filename} ]]; then
        echo $(( `date +%s` - `stat -L --format %Y $filename` ))
    else
    fi
    


    if [ "${COMP_WORDS[COMP_CWORD]}" ]
}