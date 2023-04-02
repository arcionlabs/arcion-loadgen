#!/usr/bin/env bash 

# Following regex is based on https://www.rfc-editor.org/rfc/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port

# Passing arguments by reference https://stackoverflow.com/questions/540298/passing-arguments-by-reference

# Usage:
#   urlparase associate_variable_name url
#
#       associate_variable_name will contain the parsed results of url
#
# Ex:
#   unset x         # in case variable is already used
#   declare -A x    # declare variable x as an associative array
#   urlparse x mongodb://host:123
#   declare -p x    # show 
#       declare -A y=([query]="" [scheme]="mongodb" [path]="" [fragment]="" [port]="123" [username]="" [rpath]="" [authority]="host:123" [host]="host" )
#
#   unset x; declare -A x; urlparse x mongodb://host:123
#       declare -A y=([query]="" [scheme]="mongodb" [path]="" [fragment]="" [port]="123" [username]="" [rpath]="" [authority]="host:123" [host]="host" )
#
urlparse() { # return associative array
    declare -n URLPARSE=$1
    shift
    local pattern='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?((/|$)([^?#]*))(\?([^#]*))?(#(.*))?$'
    #                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑↑    ↑        ↑  ↑        ↑ ↑
    #                    ||            |  |||            |         | |            ||    |        |  |        | |
    #                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       ||    12 rpath |  14 query | 16 fragment
    #                    1 scheme:     |  |5 userinfo@             8 :...         ||             13 ?...     15 #...
    #                                  |  4 authority                             |11 / or end-of-string
    #                                  3  //...            

    # uri capture
    uri="$@"
    # safe escaping
    uri="${uri//\`/%60}"
    uri="${uri//\"/%22}"
    # check pattern match
    [[ "$uri" =~ $pattern ]] || return 1;

    # matched
    URLPARSE[scheme]="${BASH_REMATCH[2]}"
    URLPARSE[authority]="${BASH_REMATCH[4]}"
    URLPARSE[username]="${BASH_REMATCH[6]}"
    URLPARSE[host]="${BASH_REMATCH[7]}"
    URLPARSE[port]="${BASH_REMATCH[9]}"
    URLPARSE[path]="${BASH_REMATCH[10]}"
    URLPARSE[rpath]="${BASH_REMATCH[12]}"
    URLPARSE[query]="${BASH_REMATCH[14]}"
    URLPARSE[fragment]="${BASH_REMATCH[16]}"
}
