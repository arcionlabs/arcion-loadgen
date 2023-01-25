- Get Arcion License

```bash
export ARCION_LICENSE=$(cat replicant.lic | base64)
if [ -z "$( grep '^ARCION_LICENSE=' ~/.zshrc )" ]; then echo "ARCION_LICENSE=${ARCION_LICENSE} >> ~/.zshrc; fi
```

- Create Docker network
```bash
docker network create arcnet
```

- Start MySQL source and target
```bash
docker run -d \
    --name mysql-db \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password
```
- Start Cockroach target
```
docker volume create roach1
docker volume create roach1
docker volume create roach1

docker run -d \
--name=roach1 \
--hostname=roach1 \
--net=arcnet \
-p 26257:26257 -p 8080:8080  \
-v "roach1:/cockroach/cockroach-data"  \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=roach1,roach2,roach3

docker run -d \
--name=roach2 \
--hostname=roach2 \
--net=arcnet \
-v "roach2:/cockroach/cockroach-data" \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=roach1,roach2,roach3

docker run -d \
--name=roach3 \
--hostname=roach3 \
--net=arcnet \
-v "roach3:/cockroach/cockroach-data" \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=roach1,roach2,roach3

docker exec -it roach1 ./cockroach init --insecure
```    

- Start Arcion
```bash
docker run -d \
    --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE=${ARCION_LICENSE} \
    -e SRCDB_HOST=mysql-db \
    -e DSTDB_HOST=mysql-db-2 \
    -e SRCDB_TYPE=mysql \
    -e DSTDB_TYPE=mysql \
    -p 7681:7681 \
    robertslee/sybench
```    

- Use the CLI [http://localhost:7681](http://localhost.7681)

# Running the CLI demo

- Open a browser with tabs for [Arcion](http://localhost:7681) and [tumx](http://localhost:7681)

In the first panel that pops up, Ctl-C and type the following:

```
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=roach1 DSTDB_TYPE=cockroach REPL_TYPE=snapshot ./menu.sh
```
![cockroach menu](./resources/images/cockroach/cockroach-menu.png)

- Ctrl-B 1 will show YAML files
- Ctrl-B 2 will show log files 