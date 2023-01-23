
Start demo


```bash
cd arcion-demo
docker run -d \
    --name arcion-demo \
    --network arcnet \
    -e ARCION_HOME=/arcion \
    -e MYSQL_ROOT_PASSWORD=password \
    -e PG_ROOT_PASSWORD=password \
    -e YCSB_PASSWORD=password \
    -e SBT_PASSWORD=password \
    -e SRCDB_HOST=mysql-db \
    -e SRCDB_ROOT=root \
    -e SRCDB_PW=password \
    -e DSTDB_HOST=mysql-db \
    -e DSTDB_ROOT=root \
    -e DSTDB_PW=password \
    -e SCRIPT_DIR=/ \
    -v `pwd`/arcion-jobs:/jobs \
    -v `pwd`/bin/replicant-cli-22.11.30.9:/arcion \
    -p :7681 \
    robertslee/sybench
```

