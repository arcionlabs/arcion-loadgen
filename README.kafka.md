
```bash
curl --silent --output docker-compose.yml \
  https://raw.githubusercontent.com/confluentinc/cp-all-in-one/7.3.1-post/cp-all-in-one/docker-compose.yml

cat >> docker-compose.yml <<EOF
networks:
  default:
    name: arcnet
    external: true
EOF

docker compose up -d
```
