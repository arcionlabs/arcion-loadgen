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
    --local-infile=true --secure-file-priv=
    
    
# wait for db to come up
while [ -z "$( docker logs mysql 2>&1 | grep 'ready for connections' )" ]; do sleep 10; done;    
```  