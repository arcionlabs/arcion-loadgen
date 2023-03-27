
## YugaByte

Using instructions from https://docs.yugabyte.com/preview/quick-start/docker/ 

```bash
docker run -d \
    --name yugabytesql \
    --network arcnet \
    -p :7001 -p :9000 -p :5433 -p :9042 \
    yugabytedb/yugabyte bin/yugabyted start \
    --daemon=false
```