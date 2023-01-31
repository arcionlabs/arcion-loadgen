
```bash
docker run -d \
    --name mariadb \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW

docker run -d \
    --name mariadb-2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW
```

```bash
SRCDB_HOST=mariadb DSTDB_HOST=mariadb-2 REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=mariadb DSTDB_HOST=mariadb-2 REPL_TYPE=full ./menu.sh

SRCDB_HOST=mysql-db DSTDB_HOST=mysql-db-2 REPL_TYPE=delta-snapshot ./menu.sh

SRCDB_HOST=mysql-db DSTDB_HOST=mysql-db-2 REPL_TYPE=real-time ./menu.sh
```