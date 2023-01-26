
- start singlestore (memsql)

access singlestore ui with id:password of `root:password` on [http://localhost:8081](http://localhost:8081)

```
docker run -d --net arcnet --name singlestore-2 -i --init \
    -e LICENSE_KEY="$SINGLESTORE_LICENSE" \
    -e ROOT_PASSWORD="password" \
    -e START_AFTER_INIT=Y \
    -p :3306 -p 8081:8080 \
    singlestore/cluster-in-a-box
```

- run mysql source and singlestore target with Arcion full mode
```bash
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=singlestore-2 DSTDB_TYPE=singlestore REPL_TYPE=full ./menu.sh
```