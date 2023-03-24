## SingleStore
```bash
docker run -d --net arcnet --name singlestore -i --init \
    -e LICENSE_KEY="$SINGLESTORE_LICENSE" \
    -e ROOT_PASSWORD="Passw0rd" \
    -e START_AFTER_INIT=Y \
    -p :3306 -p :8080 \
    singlestore/cluster-in-a-box
```