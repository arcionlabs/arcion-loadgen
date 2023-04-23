## MySQL

Note: `-e LANG=C.UTF-8` makes MySQL CLI display UTF-8 characters correctly in the docker console.

```bash
docker run -d \
    --name mysql \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=Passw0rd \
    -e LANG=C.UTF-8 \
    -p 3306:3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password \
    --secure-file-priv="" \
    --local-infile=true \
    --lower_case_table_names=1 
        
docker run -d \
    --name mysql2 \
    --network arcnet \
    -e MYSQL_ROOT_PASSWORD=Passw0rd \
    -e LANG=C.UTF-8 \
    -p 3306:3306 \
    mysql \
    mysqld --default-authentication-plugin=mysql_native_password \
    --secure-file-priv="" \
    --local-infile=true 
```  