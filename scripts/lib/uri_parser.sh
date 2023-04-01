#!/usr/bin/env bash 

# utility to parse uri 
# https://vpalos.com/2010/02/03/uri-parsing-using-bash-built-in-features/
# [jdbc:]postgresql://user:password@host:port/db?key=value

#
# URI parsing function
#
# The function creates global variables with the parsed results.
# It returns 0 if parsing was successful or non-zero otherwise.
#
# [schema://][user[:password]@]host[:port][/path][?[arg1=val1]...][#fragment]
#
function uri_parser() {
    declare -n URLPARSE=$1
    shift    
    # uri capture
    uri="$@"

    # safe escaping
    uri="${uri//\`/%60}"
    uri="${uri//\"/%22}"

    # top level parsing
    pattern='^(([a-z0-9]*)://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
    [[ "$uri" =~ $pattern ]] || return 1;

    # component extraction
    uri=${BASH_REMATCH[0]}
    URLPARSE[scheme]=${BASH_REMATCH[2]}
    URLPARSE[netloc]=${BASH_REMATCH[3]}
    URLPARSE[username]=${BASH_REMATCH[5]}
    URLPARSE[password]=${BASH_REMATCH[7]}
    URLPARSE[hostname]=${BASH_REMATCH[8]}
    URLPARSE[port]=${BASH_REMATCH[10]}
    URLPARSE[path]=${BASH_REMATCH[11]}
    URLPARSE[query]=${BASH_REMATCH[12]}
    URLPARSE[fragment]=${BASH_REMATCH[13]}

    # path parsing
    count=0
    path="$uri[path]"
    pattern='^/+([^/]+)'
    while [[ $path =~ $pattern ]]; do
        eval "uri_parts[$count]=\"${BASH_REMATCH[1]}\""
        path="${path:${#BASH_REMATCH[0]}}"
        let count++
    done

    # query parsing
    count=0
    query="$uri[query]"
    pattern='^[?&]+([^= ]+)(=([^&]*))?'
    while [[ $query =~ $pattern ]]; do
        eval "uri_args[$count]=\"${BASH_REMATCH[1]}\""
        eval "uri_arg_${BASH_REMATCH[1]}=\"${BASH_REMATCH[3]}\""
        query="${query:${#BASH_REMATCH[0]}}"
        let count++
    done

    # return success
    return 0
}

