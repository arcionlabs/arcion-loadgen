Convert URI to YAML file.  The resulting YAML can be used for source and destination.

- create mysql.yaml

```bash
. $SCRIPTS_DIR/lib/arcuriyaml.sh
uri_yaml mysql://arcsrc:Passw0rd@mysql | tee mysql.yaml
```

- the following YAML is generated 
```yaml
type: MYSQL
host: mysql
username: arcsrc
password: Passw0rd
max-connections: 2
max-retries: 1
port: 3306
```

- example usage in [replicant fetch-schema unit test](../../scripts/tests/fetch-schema.sh)

This will loop thru `mysql` and `postgrtesql` and fetch the schema.

```bash
dbs=(mysql postgresql)
for db in ${dbs[*]}; do
    echo $db
    uri_yaml $db://arcsrc:Passw0rd@$db | tee $db.yaml
    /arcion/bin/replicant fetch-schemas --id $$ --fetch-row-count-estimate --output-file $db.sql $db.yaml
    if (( "$?" != 0 )); then
        echo $db >> fetch-schema.err.log
    fi
done
```

- advanced usage to change the parameter

```bash
uri_yaml "mysql://user:pass@host:1234/db?a=1?b=2?a=3?max-connections=4
```

note `max-connections:4` in the resulting YAML.

the following params are ignored 
- `a=1` 
- `b=2`
- `a=3`    

```yaml
type: MYSQL
host: host
username: user
password: pass
max-connections: 4
max-retries: 1
port: 3306
```


- the following are list of all types in Replicant.  Not everything is handled.

```bash
dbs=(
AURORA_POSTGRESQL
AWS_KEYSPACES
BIGQUERY
CASSANDRA
CITUSDB
COCKROACH
COSMOSDB
CSV
DATABASE
DATABRICKS_DELTALAKE
DATABRICKS_LAKEHOUSE
DB2
DBFSStorage
DYNAMODB
FAUNADB
GREENPLUM
HANA
HIVE
IMPLY
INFORMIX
JDBC
KAFKA
LOCALSTORAGE
MARIADB
MATERIALIZE
MEMSQL
MONGODB
MONGODBATLAS
MYSQL
NETEZZA
NFS_STORAGE_BROKER
ORACLE
PINGCAP
POSTGRESQL
REDIS_STREAM
REDSHIFT
REPLICATE_METADATA
S3
S3_STORAGE_BROKER
SALESFORCE
SAP_IQ
SINGLESTORE
SKYSQL
SNOWFLAKE
SPARK
SQLITE
SQLSERVER
STORAGE_BROKER
SYBASE_ASE
TERADATA
TRAFODION
VERTICA
XA
YUGABYTE_CQL
YUGABYTESQL
)
```