
```bash
docker run -d \
    --name maria-db \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password --log-bin=mysql-log.bin
--binlog-format=ROW

docker run -d \
    --name maria-db-2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password
```

``
SRCDB_HOST=maria-db SRCDB_TYPE=mariadb DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=full ./menu.sh
``