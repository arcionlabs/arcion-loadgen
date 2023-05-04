#!/usr/bin/env bash

if [ -z "$CONFLUENT_KEY_SECRET" ]; then
  CONFLUENT_KEY_SECRET=$(echo -n "$CONFLUENT_CLUSTER_API_KEY:$CONFLUENT_CLUSTER_API_SECRET" | base64 -w 0)
fi

# docs at https://docs.confluent.io/platform/current/kafka-rest/api.html#cluster-v3

# list topics
curl -s \
  -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics | \
  jq '.data[].topic_name'

# create topic
curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics \
  -d '{"topic_name":"my-topic"}'

# produce a message
# Confluent Error Code 200=everying ok
# https://docs.confluent.io/cloud/current/api.html?ajs_aid=e6360823-be81-4347-a8a5-54f567a9a4d7&ajs_uid=1227794#section/HTTP-Guidelines

curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics/my-topic/records \
  -d '{"value":{"type":"JSON","data":"Hello World!"}}'


# create consumer group
# https://docs.confluent.io/platform/current/kafka-rest/quickstart.html#produce-and-consume-json-messages
curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.kafka.v2+json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  -d '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/consumers/testgroup


curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      http://localhost:8082/consumers/my_json_consumer



curl \
  -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics/arcdst_unicode/instances
  
  
   \
  -d '{"name": "arcdst_unicode", "format": "json", "auto.offset.reset": "earliest"}'

