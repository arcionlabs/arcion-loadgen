
sign up for trial
download zip file
unzip
add replicant.lic to the directory

- docker setup

```
docker create network arcnet
```

- get into the server
```
docker exec -it arcion-cli-arcion-cli-1 bash
```

- mysql tool inside the CLI

```
# JDBC driver required for snapshot
cd /arcion/lib
curl -O --output-dir ./ --location https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.31.tar.gz
tar xfz mysql-connector-j-8.0.31.tar.gz
mv mysql-connector-j-8.0.31/mysql-connector-j-8.0.31.jar . 
rm -rf mysql-connector-j-8.0.31 

# mysqlbin required for mysqlbinlog

# don't run the server after install
# TODO RUNLEVEL=1 did not stop fromstarting
# RUNLEVEL=1 apt-get install -y mysql-server
apt-get install -y mysql-server
systemctl disable mysql
service mysql stop
which mysqlbinlog
```

- initialize the source db
TODO: modify mysql-init.sh to take YCSB
```
export MYSQL_HOST=$SRCDB_HOST
/scripts/mysql-init.sh
mysql -h$SRCDB_HOST -uycsb -ppassword -e "select count(*) from ycsb.usertable"
mysql -h$SRCDB_HOST -uroot -ppassword -e "show databases"
mysql -h$DSTDB_HOST -uroot -ppassword -e "select count(*) from ycsb.usertable"

```

## snapshot mode
[snapshot](https://docs.arcion.io/docs/running-replicant/#replicant-snapshot-mode)
- run snapshot
-  Loading local data is disabled; this must be enabled on both the client and server sides
```
cd /arcion/replicant-cli
cat replicant.lic
export JOB=mymy
export DIR=/tmp/$JOB
mkdir -p $DIR; for f in /jobs/$JOB/*; do cat $f | envsubst > $DIR/$(basename $f); done

./bin/replicant snapshot ${DIR}/src_1.yaml ${DIR}/dst_1.yaml \
--filter ${DIR}/src_1_filter.yaml \
--extractor ${DIR}/src_1_extractor.yaml \
--applier ${DIR}/dst_1_applier.yaml \
--replace-existing \
--overwrite
```

- run full
required mysqlbin that is a part of mysql-server
io_replicate.replicate_io_cdc_heartbeat: Table does not exist on source. 
** the jdbc is required to be installed at different location than snapshot **

if --id is not specified, then jdbc driver missing is seen

## full mode

[full mode](https://docs.arcion.io/docs/running-replicant/#replicant-full-mode)
```
cd /arcion/replicant-cli
cat replicant.lic
export JOB=mymy
export DIR=/tmp/$JOB
mkdir -p $DIR; for f in /jobs/$JOB/*; do cat $f | envsubst > $DIR/$(basename $f); done

./bin/replicant full ${DIR}/src_1.yaml ${DIR}/dst_1.yaml \
--filter ${DIR}/src_1_filter.yaml \
--extractor ${DIR}/src_1_extractor.yaml \
--applier ${DIR}/dst_1_applier.yaml \
--replace-existing \
--overwrite \
--id 2
```

## realtime

```
./bin/replicant real-time ${DIR}/src_1.yaml ${DIR}/dst_1.yaml \
--filter ${DIR}/src_1_filter.yaml \
--extractor ${DIR}/src_1_extractor.yaml \
--applier ${DIR}/dst_1_applier.yaml \
--replace-existing \
--overwrite \
--id realtime
```
## delta

```
./bin/replicant delta-snapshot ${DIR}/src_1.yaml ${DIR}/dst_1.yaml \
--filter ${DIR}/src_1_filter.yaml \
--extractor ${DIR}/src_1_extractor.yaml \
--applier ${DIR}/dst_1_applier.yaml \
--replace-existing \
--overwrite \
--id delta
```


- troubleshoot
```
cat data/default/trace.log
cat data/2/trace.log

```


root      1761  0.3  0.0 160984 11576 ?        Sl   19:54   0:00 /usr/bin/qemu-x86_64 /usr/bin/sh sh /arcion/release/arcion-on-premises/compute/../core/bin/replicant full /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/src_conn.json --extractor /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/extractor.json --filter /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/filter.json /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/dst_conn.json --applier /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/applier.json --replace-existing --metadata /arcion/internal-config/core/metadata.yaml --general /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/general.yaml --statistics /arcion/internal-config/core/statistics.yaml --serialization YAML --output GUI --id 2 --overwrite
root      1929 85.6  8.3 7475304 1027540 ?     Sl   19:54   0:32 /usr/bin/qemu-x86_64 /usr/bin/java java -Duser.timezone=UTC -Djava.system.class.loader=tech.replicant.util.ReplicantClassLoader -classpath /arcion/release/arcion-on-premises/core/target/replicant-core.jar:/arcion/release/arcion-on-premises/core/lib/ts-5089.jar:/arcion/release/arcion-on-premises/core/lib/ts.jar:/arcion/release/arcion-on-premises/core/lib/* tech.replicant.Main full /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/src_conn.json --extractor /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/extractor.json --filter /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/filter.json /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/dst_conn.json --applier /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/applier.json --replace-existing --metadata /arcion/internal-config/core/metadata.yaml --general /data/compute/data/organizations/c0a85005-85a7-10e2-8185-a782a3990002/replications/c0a85005-85a7-10e2-8185-a78b2fc10007/general.yaml --statistics /arcion/internal-config/core/statistics.yaml --serialization YAML --output GUI --id 2 --overwrite