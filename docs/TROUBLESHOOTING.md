

- clean up docker
```
docker container prune
docker volume prune --force
```


- management log and replication (organization) logs
```
docker cp arcion1:/data/management/logs/ .
docker cp arcion1:/data/compute/data/organizations/ .
```