#!/usr/bin/env bash

if [ -z "$CONFLUENT_KEY_SECRET" ]; then
  CONFLUENT_KEY_SECRET=$(echo -n "$CONFLUENT_CLUSTER_API_KEY:$CONFLUENT_CLUSTER_API_SECRET" | base64 -w 0)
fi

#curl \
#  -X POST \
#  -H "Content-Type: application/json" \
#  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
#  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics \
#  -d '{"topic_name":"my-topic"}'

# Confluent Error Code 200=everying ok
# https://docs.confluent.io/cloud/current/api.html?ajs_aid=e6360823-be81-4347-a8a5-54f567a9a4d7&ajs_uid=1227794#section/HTTP-Guidelines

curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CONFLUENT_KEY_SECRET" \
  https://pkc-419q3.us-east4.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-63x616/topics/my-topic/records \
  -d '{"value":{"type":"JSON","data":"Hello World!"}}'
