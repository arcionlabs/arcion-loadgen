
export SRCDB_HOST=mysql-db
export SRCDB_TYPE=mysql
export DSTDB_HOST=mysql-db-2
export DSTDB_TYPE=mysql


```bash
docker run -d \
    --name mysql \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password

docker run -d \
    --name mysql-2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=password \
    -p :3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password
```


security
```
Use a secure connection (TLS)
MB_DB_CONNECTION_URI="mysql://<host>:<port>/<database>?user=<username>&password=<password>&useSSL=true"
Specify the server’s RSA public key
MB_DB_CONNECTION_URI="mysql://<host>:<port>/<database>?user=<username>&password=<password>&serverRsaPublicKeyFile=<path-to-file>"
(not secure) Allow public key retrieval
MB_DB_CONNECTION_URI="mysql://<host>:<port>/<database>?user=<username>&password=<password>&allowPublicKeyRetrieval=true"
(not secure) Change the MySQL user to use the older authentication plugin - example
ALTER USER 'your_mysql_user'@'your_host' IDENTIFIED WITH mysql_native_password BY 'your_mysql_password';
```