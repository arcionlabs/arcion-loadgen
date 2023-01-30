
```bash
docker run -d \
    --name maria-db \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW

docker run -d \
    --name maria-db-2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mariadb \
    mysqld --default-authentication-plugin=mysql_native_password \
    --log-bin=mysql-log.bin \
    --binlog-format=ROW
```

``
SRCDB_HOST=maria-db SRCDB_TYPE=mariadb DSTDB_HOST=maria-db-2 DSTDB_TYPE=mariadb REPL_TYPE=snapshot ./menu.sh

SRCDB_HOST=maria-db SRCDB_TYPE=mariadb DSTDB_HOST=maria-db-2 DSTDB_TYPE=mariadb REPL_TYPE=full ./menu.sh

``

https://mariadb.com/downloads/

```bash
case $(dpkg --print-architecture) in
    arm64)
    curl -O https://dlm.mariadb.com/2685406/MariaDB/mariadb-10.10.2/repo/ubuntu/mariadb-10.10.2-ubuntu-focal-amd64-debs.tar
    ;;
    amd64)
    curl -O https://dlm.mariadb.com/2690820/MariaDB/mariadb-10.10.2/bintar-linux-systemd-x86_64/mariadb-10.10.2-linux-systemd-x86_64.tar.gz
    ;;
    *)
    echo "Unsupported arch"
    ;;
esac
```