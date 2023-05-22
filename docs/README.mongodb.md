## MongoDB

Note that:
- Arcion Snapshot requires ssl and replication set
    - 3 nodes are minimum
- Arcion Real Time requires sharding
    - 1 additional node is required

https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/

### SSL and Replication Set

```bash
mkdir keyfile
openssl rand -base64 756 > keyfile/mongodb.keyfile
chmod 400 keyfile/mongodb.keyfile
```

```bash
docker run -d \
    --name mongodbcfg \
    --network arcnet \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=Passw0rd \
    -p :27017 \
    mongo mongod --replSet rs0 --configsvr 


docker run -d \
    --name mongodb \
    --network arcnet \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=Passw0rd \
    -p :27017 \
    -v `pwd`/keyfile:c \
    mongo mongod --keyFile /data/configdb/keyfile/mongodb.keyfile --replSet rs0

docker run -d \
    --name mongodb2 \
    --network arcnet \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=Passw0rd \
    -p :27017 \
    -v `pwd`/keyfile:/data/configdb/keyfile \
    mongo mongod --keyFile /data/configdb/keyfile/mongodb.keyfile --replSet rs0

docker run -d \
    --name mongodb3 \
    --network arcnet \
    -e MONGO_INITDB_ROOT_USERNAME=root \
    -e MONGO_INITDB_ROOT_PASSWORD=Passw0rd \
    -p :27017 \
    -v `pwd`/keyfile:/data/configdb/keyfile \
    mongo mongod --keyFile /data/configdb/keyfile/mongodb.keyfile --replSet rs0


docker run -d \
    --name mongodb-express \
    --network arcnet \
    -e ME_CONFIG_MONGODB_ADMINUSERNAME=root \
    -e ME_CONFIG_MONGODB_ADMINPASSWORD=Passw0rd \
    -e ME_CONFIG_MONGODB_URL="mongodb://root:Passw0rd@mongodb:27017/" \
    -p 18081:8081 \
    mongo-express 
```

### Sharding


As noted in [MongoDB's Docker Hub documentation](https://hub.docker.com/_/mongo),
"authentication in MongoDB is fairly complex (although disabled by default)".  

https://www.mongodb.com/docs/manual/reference/sql-comparison/ is a good reference
https://www.mongodb.com/docs/manual/tutorial/convert-standalone-to-replica-set/
https://www.mongodb.com/docs/manual/tutorial/deploy-replica-set-for-testing/
https://www.mongodb.com/docs/manual/tutorial/deploy-replica-set-with-keyfile-access-control/#std-label-deploy-repl-set-with-auth

