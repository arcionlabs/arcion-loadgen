#!/usr/bin/env bash 

# Following regex is based on https://www.rfc-editor.org/rfc/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port
#
export URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?((/|$)([^?#]*))(\?([^#]*))?(#(.*))?$'
#                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑↑    ↑        ↑  ↑        ↑ ↑
#                    ||            |  |||            |         | |            ||    |        |  |        | |
#                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       ||    12 rpath |  14 query | 16 fragment
#                    1 scheme:     |  |5 userinfo@             8 :...         ||             13 ?...     15 #...
#                                  |  4 authority                             |11 / or end-of-string
#                                  3  //...            

urlparse_scheme () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[2]}"
}

urlparse_authority () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[4]}"
}

urlparse_user () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[6]}"
}

urlparse_host () {
    if [[ "$@" =~ $URI_REGEX ]]; then
        echo "${BASH_REMATCH[7]}"
    else    
        echo "no match"
    fi
}


urlparse_port () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[9]}"
}

urlparse_path () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[10]}"
}

urlparse_rpath () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[12]}"
}

urlparse_query () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[14]}"
}

urlparse_fragment () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[16]}"
}