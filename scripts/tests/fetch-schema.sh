#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/arcuriyaml.sh

# works ok
dbs_ok=(
yugabytesql    
postgresql
mysql
mariadb
singlestore
)

# the following fails
dbs_fail=(
cockroach
sqlserver
informix
)

# dbs to test
dbs=(
)

# run the test
for db in ${dbs[*]}; do
    echo $db
    uri_yaml $db://arcsrc:Passw0rd@$db | tee $db.yaml
    /arcion/bin/replicant fetch-schemas --id $$ --fetch-row-count-estimate --output-file $db.sql $db.yaml
    if (( "$?" != 0 )); then
        echo $db >> fetch-schema.err.log
    fi
done

