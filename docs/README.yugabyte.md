
## YugaByte

Using instructions from https://docs.yugabyte.com/preview/quick-start/docker/ 

```bash
docker run -d \
    --name yugabytesql \
    --network arcnet \
    -p7001:7001 -p9000:9000 -p5433:5433 -p9042:9042 \
    yugabytedb/yugabyte bin/yugabyted start \
    --daemon=false
```