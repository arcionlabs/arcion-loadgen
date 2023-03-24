NOTE: CockroachDB as the source using snapshot replication mode works.  

These instructions assume base environment is already setup from the [README.md](README.md).

- Start CockroachDB

This is a copy/paste from [Start a Cluster in Docker (Insecure) in Mac](https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-mac.html) with the following change(s):
  - use `arcnet` instead of `roachnet`

## CockroachDB

Stopped working working for source snapshot and destination.

```bash
docker run -d \
    --name=cockroach \
    --hostname=cockroach \
    --net=arcnet \
    -p :26257 -p :8080  \
    cockroachdb/cockroach:v22.2.3 start-single-node \
    --insecure 
```


```
export PGCLIENTENCODING='utf-8'
psql postgresql://root:password@cockroach-1:26257/?sslmode=disable
```


psql "postgresql://$CRL_USER:$CRL_PASS@$CRL_HOST:26257/defaultdb?sslmode=verify-full&sslrootcert=./root.crt"