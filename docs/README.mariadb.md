## MariaDB

```bash
docker run -d \
    --name mariadb \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=Passw0rd \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW

docker run -d \
    --name mariadb2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=Passw0rd \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW    
```