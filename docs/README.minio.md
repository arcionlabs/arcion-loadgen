
## Minio

Using Minio instruction from [here](https://min.io/docs/minio/container/index.html) with the following changes:
- add `-d`
- change name to `s3`
- add `--network arcnet`
- change client port to `9100` and `9190`

```bash
docker run -d \
    --name s3 \
    --network arcnet \
    -p 9100:9000 \
    -p 9190:9090 \
    -e MINIO_ROOT_USER=root \
    -e MINIO_ROOT_PASSWORD=Passw0rd \
    quay.io/minio/minio server /data --console-address ":9090"
```  