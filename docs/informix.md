
more info at https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md

Default root id/password = informix/in4mix

```bash
docker run -d \
  --name informix \
  --network arcnet \
  -p :9088 \
  -p :9089 \
  -p :27017 \
  -p :27018 \
  -p :27883 \
  -e LICENSE=accept \
  -e RUN_FILE_POST_INIT=informix.root.sh \
  -v $ARCDEMO_DIR/docs/informix.root.sh:/opt/ibm/config/informix.root.sh \
  ibmcom/informix-developer-database:latest
```      