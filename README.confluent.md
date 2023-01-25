
Following [Confluent Quick Start](https://docs.confluent.io/platform/current/platform-quickstart.html#step-1-download-and-start-cp)

```bash
curl --silent --output docker-compose.yml \
  https://raw.githubusercontent.com/confluentinc/cp-all-in-one/7.3.1-post/cp-all-in-one/docker-compose.yml

cat >> docker-compose.yaml <<EOF
networks:
  default:
    name: arcnet
    external: true
EOF
```