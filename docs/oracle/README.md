Oracle XE and Oracle EE instructions adopted from [Oracle](https://github.com/oracle/docker-images/tree/main/OracleDatabase).  

- Oracle XE does not require OTN download.  There are size (limitations)[https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinl/licensing-restrictions.html]
- Oracle EE requires OTN download.

# Oracle XE

build the oracle xe contaimer image
```bash
git clone https://github.com/oracle/docker-images oracle-docker-images
cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 

./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
```

```bash
for inst in 1 2; do
    docker volume create oraxe${inst}
    docker run -d \
        --name oraxe${inst} \
        --network arcnet \
        -p :1521 \
        -p :5500 \
        -e ORACLE_PWD=Passw0rd \
        -v oraxe${inst}:/opt/oracle/oradata \
        oracle/database:21.3.0-xe    
    while [ -z "$( docker logs oraxe${inst} 2>&1 | grep 'DATABASE IS READY TO USE!' )" ]; do echo sleep 10; sleep 10; done;
done
```

# Oracle EE

Download Oracle binary and place in 19.3.0 directory

```bash
git clone https://github.com/oracle/docker-images oracle-docker-images
cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles/19.3.0
```

Build the docker image

```bash
cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'
```

create two oracle docker containers. one for the source and the other for destination if oracle to oracle replication is intended.  Otherwise, just one is sufficient.  `oraee1` is will serve as the source.  `oraee2` will serve as destination.

each container takes about 10 min to complete

```bash
for inst in 1 2; do
    docker volume create oraee${inst}
    docker run -d \
        --name oraee${inst} \
        --network arcnet \
        -p :1521 \
        -p :5500 \
        -p :2484 \
        -e ORACLE_SID=orcl \
        -e ORACLE_PDB=orclpdb1 \
        -e ORACLE_PWD=Passw0rd \
        -e ORACLE_EDITION=enterprise \
        -e ENABLE_ARCHIVELOG=true \
        -e AUTO_MEM_CALCULATION=false \
        -v oraee${inst}:/opt/oracle/oradata \
        oracle/database:19.3.0-ee    
    while [ -z "$( docker logs oraee${inst} 2>&1 | grep 'DATABASE IS READY TO USE!' )" ]; do echo sleep 10; sleep 10; done;
done
```

