## MySQL

Note: `-e LANG=C.UTF-8` makes MySQL CLI display UTF-8 characters correctly in the docker console.

```bash
inst=
docker volume create mysql${inst}
docker run -d \
    --name mysql${inst} \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=Passw0rd \
    -e LANG=C.UTF-8 \
    -p :3306 \
    -v mysql${inst}:/var/lib/mysql \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password \
    --secure-file-priv="" \
    --local-infile=true \
    --lower_case_table_names=1 \
    --innodb_redo_log_capacity=$((200*1024*1024))
         
```  