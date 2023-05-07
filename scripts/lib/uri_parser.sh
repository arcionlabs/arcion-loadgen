#!/usr/bin/env bash 

# utility to parse uri 
# https://vpalos.com/2010/02/03/uri-parsing-using-bash-built-in-features/
# [jdbc:]postgresql://user:password@host:port/db?key=value#frag

#
# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
# unset uri; declare -A uri; unset uri_path; declare -a uri_path; unset uri_query; declare -A uri_query; uri_parser uri uri_path uri_query "mysql://user:pass@host:port/db?a=1?
# unset uri; declare -A uri; unset uri_path; declare -a uri_path; unset uri_query; declare -A uri_query; uri_parser uri uri_path uri_query oraee/redo
function uri_parser() {
    declare -n URLPARSE=$1
    declare -n PATHPARSE=$2
    declare -n QUERYPARSE=$3
    shift    
    shift    
    shift    
    # uri capture
    uri="$@"

    # safe escaping
    uri="${uri//\`/%60}"
    uri="${uri//\"/%22}"

    # top level parsing
    # https://tldp.org/LDP/abs/html/x17129.html
    #                              N
    #                   *     ?    O    +
    #                   0-n   0-1  T    1-n
    #                      //              :           @             :             /           ?          #
    pattern='^(([a-z0-9]*)://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/([^?]*))?(\?([^#]*))?(#(.*))?$'
    #         1|               3||         6|             8hostname 9 10port     11 |        13 |        15
    #          2scheme          4|          7password                               12path      14query    16frag
    #                            5username          
    [[ "$uri" =~ $pattern ]] || return 1;

    # DEBUG
    #echo ${BASH_REMATCH[*]} >&2
    # component extraction
    uri=${BASH_REMATCH[0]}
    URLPARSE[scheme]="${BASH_REMATCH[2]}"
    URLPARSE[netloc]="${BASH_REMATCH[3]}"
    URLPARSE[username]="${BASH_REMATCH[5]}"
    URLPARSE[password]="${BASH_REMATCH[7]}"
    URLPARSE[hostname]="${BASH_REMATCH[8]}"
    URLPARSE[port]="${BASH_REMATCH[10]}"
    URLPARSE[path]="${BASH_REMATCH[12]}"
    URLPARSE[query]="${BASH_REMATCH[14]}"
    URLPARSE[fragment]="${BASH_REMATCH[16]}"

    # save for parsing later
    local path="${BASH_REMATCH[11]}"  # need the leading delim
    local query="${BASH_REMATCH[13]}" # need the leading delim

    # DEBUG
    #echo "path=$path" >&2
    #echo "query=$query" >&2

    # path parsing
    local count=0
    local pattern='[\/\?;&#]+([^\/\?;&#]*)'
    while [[ $path =~ $pattern ]]; do
        PATHPARSE[$count]="${BASH_REMATCH[1]}"
        path="${path:${#BASH_REMATCH[0]}}"
        # DEBUG
        #echo "path=${PATHPARSE[$count]}" >&2
        let count++
    done
    #[ "${path}" ] && PATHPARSE[$count]="${path}"

    # query parsing
    count=0
    pattern='[\?&;]+([^= ]+)(=([^\?&;]*))'
    #                  key     = val 
    while [[ $query =~ $pattern ]]; do
        QUERYPARSE[${BASH_REMATCH[1]}]="${BASH_REMATCH[3]}"
        query="${query:${#BASH_REMATCH[0]}}"
        # DEBUG
        # echo "query ${BASH_REMATCH[1]}=${QUERYPARSE[${BASH_REMATCH[1]}]}" >&2
        let count++
    done

    # return success
    return 0
}

