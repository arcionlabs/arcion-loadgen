
## Kafka 2 node local setup

An exmaple of real-time replication from mysql to kafka broker

```bash
./arcdemo.sh real-time mysql broker
```

Below is Kakfa docker setup required.  Docker compose of zookeeper and broker from https://developer.confluent.io/quickstart/kafka-docker/

```bash
cat >docker-compose-kafka-quickstart.yaml <<EOF
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
    container_name: broker
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
networks:
  default:
    name: arcnet
    external: true
EOF

docker compose -f docker-compose-kafka-quickstart.yaml up -d
```

## Kafka Cloud (Confluent)

An exmaple of real-time replication from mysql to kafka broker

```bash
./arcdemo.sh real-time mysql broker/confluent
```

Below is Confluent Cloud setup required. Create a account with [Confluent.io](https://www.confluent.io/) using the [Get Started for Free](https://www.confluent.io/get-started/) link.  After the account has been created, following info are needed.

- CLUSTER_API_KEY
- CLUSTER_API_SECRET
- BOOTSTRAP_SERVER

The info will be passed to the script as environmental variables.
The `xxxxxxxxxx` should be replaced with the actual.
Type the below command from on your Linux, Mac, or Windows WSL Terminal.

```bash
# stop arcion-demo if already running
docker rm arcion-demo --force

# setup the env variable
export CONFLUENT_CLUSTER_API_KEY="xxxxxxxxxx"
export CONFLUENT_CLUSTER_API_SECRET="xxxxxxxxxx"
export CONFLUENT_BOOTSTRAP_SERVER="xxxxxxxxxx"

# start with Confluent setup
docker run -d --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -e CONFLUENT_CLUSTER_API_KEY="$CONFLUENT_CLUSTER_API_KEY" \
    -e CONFLUENT_CLUSTER_API_SECRET="$CONFLUENT_CLUSTER_API_SECRET" \
    -e CONFLUENT_BOOTSTRAP_SERVER="$CONFLUENT_BOOTSTRAP_SERVER" \
    -e LANG=C.UTF-8 \
    -p 7681:7681 \
    robertslee/arcdemo
```  

## Validation

### CLI way for the on-prem

Test the broker
```bash
docker exec broker \
kafka-topics --bootstrap-server broker:9092 \
             --create \
             --topic quickstart

docker exec -i broker \
kafka-console-producer --bootstrap-server broker:9092 \
                       --topic quickstart <<EOF
Hi $( date )
EOF

docker exec --interactive --tty broker \
kafka-console-consumer --bootstrap-server broker:9092 \
                       --topic quickstart \
                       --from-beginning
```


```bash
docker exec broker \
kafka-topics --bootstrap-server broker:9092 --list

docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 \
    --from-beginning --topic arcdst_usertable
docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 \
    --from-beginning --topic arcdst_sbtest1

docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 \
    --from-beginning --topic arcdst_sbtest1_cdc_logs
docker exec --interactive --tty broker kafka-console-consumer --bootstrap-server broker:9092 \
    --from-beginning --topic arcdst_usertable_cdc_logs
```

### Confluent Cloud

Open the browser and see the topic. 
Two topics are created per table. 
Topic name with `_cdc_logs` are real-time.
Topic name with just table table is the snapshot.
 
During replication, Replicant stores metadata information related to replicated tables in a special topic with the prefix `replicate_io_replication_schema`. 

![](./resources/images/kafka/confluent-topics.png)

