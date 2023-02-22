This is [Arcion](https://www.arcion.io/) Replicant demos using [CLI](https://docs.arcion.io/docs/quickstart/index.html) and [GUI](https://docs.arcion.io/docs/arcion-cloud-dashboard/quickstart/index.html).

# Overview
The diagram below depicts the components of the demo.
- Load Generator
- Source host
- Arcion host with dedicated metadata database
- Target host

```mermaid
graph LR
    L[Load Generator<br>sysbench<br>YCSB] --> S
    subgraph Arcion Cluster
        A1
        M[(Meta <br>Data)]
    end
    S[(Source <br>Host)] --> A1[Arcion <br> Node 1]
    A1 --> T[(Target <br>Host)]
```

A host has two database and two user IDs.  The Load Generator is setup to use `arcsrc` username and write to `arcsrc` database.

```mermaid
graph LR
    L[Load Generator<br>sysbench<br>YCSB] --> arcsrc
    subgraph Source Host
        arcsrc
        arcdst
    end
   
```

Data is replicated from `arcsrc` to `arcdst` database.

```mermaid
graph LR
    subgraph Target
        das[Target arcsrc]
        dad[Target arcdst]
    end   
    subgraph Source
        sas[Source arcsrc]
        sad[Source arcdst]
    end
    sas --> Arcion
    Arcion --> dad
 
```

Source and Target can be the same host. `arcsrc` database is replicated to `arcdst` database.

```mermaid
graph TB
    subgraph Host
        arcsrc
        arcdst
    end   
    arcsrc --> Arcion
    Arcion --> arcdst
 
```

# Demo data source and targets

Arcion has the following replication types: 
- `snapshot` does bulk export and import
- `real-time` does CDC
- `full` does `snapahot` + `realtime`
- `delta-snapshot` does export at 10 sec intervals

## Source 
Database sources that support `snapshot`, `real-time` and `full`
- MariaDB
- MySQL
- Postgres
- Kafka (works as destination for now)
- MongoDB (works as destination for now)

Data sources that support `snapshot` and potentially `delta-snapshot`:
- CockroachDB
- SingleStore
- YugaByteSQL

The above sources work as destinations as well.  For example:

```bash
SRCDB_HOST=mysql DSTDB_HOST=mysql REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=mysql DSTDB_HOST=mariadb REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=mariadb DSTDB_HOST=cockroach-1 REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=cockroach-1 DSTDB_HOST=postgresql REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=postgresql DSTDB_HOST=kafka REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=postgresql DSTDB_HOST=mongodb REPL_TYPE=snapshot ./menu.sh
```

Databases such as DB2, Oracle, SQL Server, Sybase will be added to the demo in the future.  

## Target

All databases can be targets

# CLI Demo Instructions

![console](./resources/images/cli/Screenshot%202023-01-26%20at%2010.08.03%20AM.png)

[asciinema](https://asciinema.org/a/554683) of typing the below commands.

Below instructions assume MacOS and Linux.  For the Windows users, use the single line version of the commands without the `\`

# Minimal Demo Docker Setup

## Get Arcion License

Make sure $ARCION_LICENSE is not blank and is valid

```bash
export ARCION_LICENSE="$(cat replicant.lic | base64)"
if [ -z "${ARCION_LICENSE}" ]; then echo "ERROR: ARCION_LICENSE is blank"; fi
echo "${ARCION_LICENSE}" | base64 -d
```

- Save Arcion License for reuse
```bash
if [ -f ~/.zshrc ]; then echo "export ARCION_LICENSE=\"${ARCION_LICENSE}\"" >> ~/.zshrc; fi
if [ -f ~/.bashrc ]; then echo "export ARCION_LICENSE=\"${ARCION_LICENSE}\"" >> ~/.bashrc; fi
```

## Create Docker network

```bash
docker network create arcnet
```

## Postgres

Postgres will be used for:
- Arcion's UI
- Arcion replication metadata
- Arcion source and destination
```bash
# postgres with SSL setup
docker run -d \
    --name postgresql \
    --network arcnet \
    -e POSTGRES_USER=root \
    -e POSTGRES_PASSWORD=password \
    -p :5432 \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=10 \
    -c ssl=on \
    -c max_connections=300 \
    -c shared_buffers=80MB \
    -c ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem \
    -c ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key    

# wait for db to come up
while [ -z "$( docker logs postgresql 2>&1 | grep 'database system is ready to accept connections' )" ]; do sleep 10; done;

# install wal2json for cdc
docker exec -it postgresql sh -c "apt update && apt install -y postgresql-15-wal2json postgresql-contrib"

# setup for Acrion UI and metadata
docker exec -i postgresql psql -Uroot<<EOF
CREATE USER arcion PASSWORD 'password';
CREATE DATABASE arcion WITH OWNER arcion;
CREATE DATABASE io_replicate WITH OWNER arcion;
EOF
```
## Arcion Load Generator

```bash
docker run -d --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -p 7681:7681 \
    robertslee/arcdemo
```    

# Optional Databases

## Arcion UI
```bash
docker run -d --name arcion-ui \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -e DB_HOST=postgresql \
    -e DB_PORT=5432 \
    -e DB_DATABASE=arcion \
    -e DB_USERNAME=arcion \
    -e DB_PASSWORD=password \
    -p 8080:8080 \
    arcionlabs/replicant-on-premises:latest-arm64

# make sure there are no warnings about license
docker logs arcion-ui
```    

## MySQL

```bash
docker run -d \
    --name mysql \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password \
    --local-infile=true

# wait for db to come up
while [ -z "$( docker logs mysql 2>&1 | grep 'ready for connections' )" ]; do sleep 10; done;    
```    

## MariaDB

```bash
docker run -d \
    --name mariadb \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW
```

## SingleStore
```bash
docker run -d --net arcnet --name singlestore -i --init \
    -e LICENSE_KEY="$SINGLESTORE_LICENSE" \
    -e ROOT_PASSWORD="password" \
    -e START_AFTER_INIT=Y \
    -p :3306 -p :8080 \
    singlestore/cluster-in-a-box
```

## CockroachDB
```
docker volume create roach1
docker volume create roach2
docker volume create roach3

docker run -d \
    --name=cockroach-1 \
    --hostname=cockroach-1 \
    --net=arcnet \
    -p :26257 -p :8080  \
    cockroachdb/cockroach:v22.2.3 start \
    --insecure \
    --join=cockroach-1,cockroach-2,cockroach-3

docker run -d \
    --name=cockroach-2 \
    --hostname=cockroach-2 \
    --net=arcnet \
    -p :26257 -p :8080  \
    cockroachdb/cockroach:v22.2.3 start \
    --insecure \
    --join=cockroach-1,cockroach-2,cockroach-3

docker run -d \
    --name=cockroach-3 \
    --hostname=cockroach-3 \
    --net=arcnet \
    -p :26257 -p :8080  \
    cockroachdb/cockroach:v22.2.3 start \
    --insecure \
    --join=cockroach-1,cockroach-2,cockroach-3

docker exec -it cockroach-1 ./cockroach init --insecure
```

## MongoDB

https://www.mongodb.com/docs/manual/reference/sql-comparison/ is a good reference

```bash
docker run -d \
    --name mongodb \
    --network arcnet \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=password \
    -p :27017 \
    mongo 

docker run -d \
    --name mongodb-express \
    --network arcnet \
    -e ME_CONFIG_MONGODB_ADMINUSERNAME=root \
    -e ME_CONFIG_MONGODB_ADMINPASSWORD=password \
    -e ME_CONFIG_MONGODB_URL="mongodb://root:password@mongodb:27017/" \
    -p 18081:8081 \
    mongo-express 
```

## Kafka

Instructions from [here](https://developer.confluent.io/quickstart/kafka-docker)

```
curl --silent --output docker-compose.yml \
  https://raw.githubusercontent.com/confluentinc/cp-all-in-one/7.3.1-post/cp-all-in-one/docker-compose.yml

# change broker name to kafka to make demo easier
cat docker-compose.yml | sed s/broker/kafka/g > docker-compose-kafka.yml

cat >>docker-compose-kafka.yml <<EOF 
networks:
  default:
    name: arcnet
    external: true
EOF

docker compose -f docker-compose-kafka.yml up -d
```
Alternate setup that only has zookeeper and Kafka https://developer.confluent.io/quickstart/kafka-docker/
```
cat > compose-kafka-quickstart.yaml <EOF
---
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.3.0
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  broker:
    image: confluentinc/cp-kafka:7.3.0
    container_name: kafka
    ports:
    # To learn about configuring Kafka for access across networks see
    # https://www.confluent.io/blog/kafka-client-cannot-connect-to-broker-on-aws-on-docker-etc/
      - "9092:9092"
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://broker:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
EOF

docker compose -f docker-compose-kafka-quickstart.yml up -d

docker exec -it kafka kafka-console-consumer --bootstrap-server kafka:29092 \
                       --topic arcdst \
                       --from-beginning

## Minio

Using Minio instruction from [here](https://min.io/docs/minio/container/index.html) with the following changes:
- add `-d`
- change name to `s3`
- add `--network arcnet`
- change client port to `9100` and `9190`

```bash
docker run -d \
    --name s3 \
    --network arcnet \
    -p 9100:9000 \
    -p 9190:9090 \
    -e MINIO_ROOT_USER=root \
    -e MINIO_ROOT_PASSWORD=password \
    quay.io/minio/minio server /data --console-address ":9090"
```  

## YugaByte

Using instructions from https://docs.yugabyte.com/preview/quick-start/docker/ 

```bash
docker run -d 
    --name yugabytesql \
    --network arcnet \
    -p7001:7001 -p9000:9000 -p5433:5433 -p9042:9042 \
    yugabytedb/yugabyte bin/yugabyted start\
    --daemon=false
```

# Work In Progress

Below is not in the demo YET but supports by Arcion.


# Running the CLI demo

Open a browser with tabs for [Arcion CLI](http://localhost:7681)

[tmux](https://man7.org/linux/man-pages/man1/tmux.1.html) is used in this console. Useful `tmux` commands are:

 
In the console windows, type the following for fully automated mode.

- run mysql source and target with Arcion snapshot mode
```bash
SRCDB_HOST=mysql DSTDB_HOST=mysql REPL_TYPE=snapshot ./menu.sh
```
- run mysql source and target with Arcion real-time mode
```bash
SRCDB_HOST=mysql DSTDB_HOST=mysql REPL_TYPE=real-time ./menu.sh
```
- run mysql source and target with Arcion real-time mode
```bash
SRCDB_HOST=mysql DSTDB_HOST=mysql REPL_TYPE=delta-snapshot ./menu.sh
```
- run mysql source and target with Arcion full mode
```bash
SRCDB_HOST=mysql DSTDB_HOST=mysql REPL_TYPE=full ./menu.sh
```
  NOTE: This mode does not stop.  type `pkill java` to stop the process.

- run in interactive mode where system asks for source and target
```bash
unset SRCDB_HOST SRCDB_TYPE DSTDB_HOST DSTDB_TYPE REPL_TYPE; ./menu.sh
```
# view Conole, Cfg and Logs

- To Stop the Run

1. press `[Ctrl + b]`, then `3` 
2. type `pkill java`
3. press `[Ctrl + b]`, then `0` 

- Console View after successful run

`[Ctrl + b]` then `0` for the Arcion YAML files.

![Arcion YAML](./resources/images/cli/Screenshot%202023-01-26%20at%2010.10.14%20AM.png)

- `[Ctrl + b]` then `1` for the Arcion YAML files.

Use [vi](https://manpages.ubuntu.com/manpages/xenial/man1/nvi.1.html) directory tree view to navigate.

![Arcion YAML](./resources/images/cli/Screenshot%202023-01-26%20at%2010.10.37%20AM.png)

- `[Ctrl + b]` then `2` for the Arcion trace and error files.

Use [vi](https://manpages.ubuntu.com/manpages/xenial/man1/nvi.1.html) directory tree view to navigate. 

![Arcion YAML](./resources/images/cli/Screenshot%202023-01-26%20at%2010.10.50%20AM.png)