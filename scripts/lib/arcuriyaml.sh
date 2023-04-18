#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/uri_parser.sh

# heredoc: https://en.wikipedia.org/wiki/Here_document#Unix_shells
# bash refrence: https://tldp.org/LDP/abs/html/index.html
# variable ending with the following are typed
#   _a=array
#   _d=dict
#   _i=int
#   without are a string

# TODO: max-connections 2 for mysql

all_yaml() {
    declare -n all_yaml_uri_d=$1
    declare -n all_yaml_query_d=$2

cat <<EOF
type: ${all_yaml_uri_d[scheme]^^}
host: ${all_yaml_uri_d[hostname]}
username: ${all_yaml_uri_d[username]}
password: ${all_yaml_uri_d[password]}
max-connections: ${all_yaml_query_d[max-connections]:-2}
max-retries: ${all_yaml_query_d[max-retries]:-1}
EOF
}

mysql_yaml() {
    declare -n mysql_yaml_uri_d=$1
    declare -n mysql_yaml_query_d=$1

    all_yaml mysql_yaml_uri_d mysql_yaml_query_d

cat <<EOF
port: ${uri_d[port]:-3306}
EOF
}

inf_yaml() {
    declare -n inf_yaml_uri_d=$1
    declare -n inf_yaml_query_d=$2

    all_yaml inf_yaml_uri_d inf_yaml_query_d

cat <<EOF
port: ${uri_d[port]:-9088}
database: ${uri_d[path]}
# for CDC
server: informix
informix-user-password: in4mix
EOF
}

postgresql_yaml() {
    declare -n postgresql_yaml_uri_d=$1
    declare -n postgresql_yaml_query_d=$2

    all_yaml postgresql_yaml_uri_d postgresql_yaml_query_d

cat <<EOF
port: ${postgresql_yaml_uri_d[port]:-5432}
database: ${postgresql_yaml_uri_d[path]:-${postgresql_yaml_uri_d[username]}}
EOF
}

cockroach_yaml() {
    declare -n cockroach_yaml_uri_d=$1
    declare -n cockroach_yaml_query_d=$2

    all_yaml cockroach_yaml_uri_d cockroach_yaml_query_d

cat <<EOF
port: ${cockroach_yaml_uri_d[port]:-26257}
database: ${cockroach_yaml_uri_d[path]:-${cockroach_yaml_uri_d[username]}}
EOF
}

yugabytesql_yaml() {
    declare -n yugabytesql_yaml_uri_d=$1
    declare -n yugabytesql_yaml_query_d=$2

    all_yaml yugabytesql_yaml_uri_d yugabytesql_yaml_query_d

cat <<EOF
port: ${yugabytesql_yaml_uri_d[port]:-5433}
database: ${yugabytesql_yaml_uri_d[path]:-${yugabytesql_yaml_uri_d[username]}}
EOF
}


ora_yaml() {
    declare -n ora_uri_d=$1
    declare -n ora_query_d=$2

    all_yaml ora_uri_d ora_query_d

cat <<EOF
port: ${ora_uri_d[port]:-1521}
service-name: ${ora_uri_d[path]}
EOF
}

sqlserver_yaml() {
    declare -n sqlserver_uri_d=$1
    declare -n sqlserver_query_d=$2

    all_yaml sqlserver_uri_d sqlserver_query_d

cat <<EOF
port: ${sqlserver_uri_d[port]:-1433}
database: ${sqlserver_uri_d[path]:-${sqlserver_uri_d[username]}}
EOF
}

# generate YAML from URI
uri_yaml() {
    unset uri; declare -A uri;  
    unset uri_path; declare -a uri_path;  
    unset uri_query; declare -A uri_query;  
    uri_parser uri uri_path uri_query "$1"

    if (( "$?" != 0 )); then
        return $?
    fi

    case ${uri[scheme]} in
        postgresql) postgresql_yaml uri uri_query;;
        cockroach) cockroach_yaml uri uri_query;;
        yugabytesql) yugabytesql_yaml uri uri_query;;
        mysql|mariadb|singlestore) mysql_yaml uri uri_query;;
        sqlserver) sqlserver_yaml uri uri_query;;
        informix) inf_yaml uri uri_query;;
        oracle) ora_yaml uri uri_query;;
        *) all_yaml uri uri_query;;
    esac
}
