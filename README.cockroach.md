NOTE: CockroachDB as the source using snapshot replication mode works.  

These instructions assume base environment is already setup from the [README.md](README.md).

- Start CockroachDB

This is a copy/paste from [Start a Cluster in Docker (Insecure) in Mac](https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-mac.html) with the following change(s):
  - use `arcnet` instead of `roachnet`

```
docker volume create roach1
docker volume create roach2
docker volume create roach3

docker run -d \
--name=cockroach-1 \
--hostname=cockroach-1 \
--net=arcnet \
-p :26257 -p :8080  \
-v "roach1:/cockroach/cockroach-data"  \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=cockroach-1,cockroach-2,cockroach-3

docker run -d \
--name=cockroach-2 \
--hostname=cockroach-2 \
--net=arcnet \
-p :26257 -p :8080  \
-v "roach2:/cockroach/cockroach-data" \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=cockroach-1,cockroach-2,cockroach-3

docker run -d \
--name=cockroach-3 \
--hostname=cockroach-3 \
--net=arcnet \
-p :26257 -p :8080  \
-v "roach3:/cockroach/cockroach-data" \
cockroachdb/cockroach:v22.2.3 start \
--insecure \
--join=cockroach-1,cockroach-2,cockroach-3

docker exec -it cockroach-1 ./cockroach init --insecure
```    

- Use the CLI [http://localhost:7681](http://localhost.7681)

# Running the CLI demo

- Open a browser with tabs for [Arcion](http://localhost:7681) and [tumx](http://localhost:7681)

In the first panel that pops up, Ctl-C and type the following:

```
SRCDB_HOST=mariadb DSTDB_HOST=cockroach-1 REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=mariadb DSTDB_HOST=cockroach-1 REPL_TYPE=real-time ./menu.sh
SRCDB_HOST=mariadb DSTDB_HOST=cockroach-1 REPL_TYPE=delta-snapshot ./menu.sh
SRCDB_HOST=mariadb DSTDB_HOST=cockroach-1 REPL_TYPE=full ./menu.sh

SRCDB_HOST=cockroach-1 DSTDB_HOST=mysql REPL_TYPE=snapshot ./menu.sh
```
![cockroach menu](./resources/images/cockroach/cockroach-menu.png)

The following combinations do not work as of yet.  The configs can be viewed via the `tmux` windows 1 and error messages `tmux` windows 2.


```
export PGCLIENTENCODING='utf-8'
psql postgresql://root:password@cockroach-1:26257/?sslmode=disable
```


psql "postgresql://$CRL_USER:$CRL_PASS@$CRL_HOST:26257/defaultdb?sslmode=verify-full&sslrootcert=./root.crt"