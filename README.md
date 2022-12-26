# ycsb-ui
 
manual set of YCSB

docker setup of YCSB

start mysql

```
apt install net-tools
```

[MySQL Docker](https://hub.docker.com/_/mysql)

Docker prep
```bash
docker volume create mysql
```

```bash
docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=password -d --restart unless-stopped -v mysql:/var/lib/mysql  mysql:latest
docker logs mysql
docker ps --filter name=mysql
apt install mysql-client-core-8.0  

docker exec -it mysql mysql -uroot -p
CREATE USER 'ycsb'@'%' IDENTIFIED BY 'password';
GRANT ALL ON ycsb.* to 'ycsb'@'%';
CREATE DATABSSE ycsb;
USE ycsb;
CREATE TABLE usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT
);
FLUSH PRIVILEGES;
```
- test
```
docker exec -it mysql mysql -uycsb -p
mysql -uycsb --host 127.0.0.1 -Dycsb -p 
```

```
mkdir jdbc
cd jdbc
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.31.tar.gz
gzip -d -c mysql-connector-j-8.0.31.tar.gz | tar -xvf -

```
mysql -u ycsb -D ycsb -e "truncate usertable" --host 127.0.0.1 -p
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://127.0.0.1/ycsb" -p db.user=root -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=false -p db.batchsize=1000 -p recordcount=100000 | tee mysql.nobatch.log

mysql -u ycsb -D ycsb -e "truncate usertable" --host 127.0.0.1 -p
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://127.0.0.1/ycsb" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000  | tee mysql.batch.log

mysql -u ycsb -D ycsb -e "truncate usertable" --host 127.0.0.1 -p
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://127.0.0.1/ycsb?rewriteBatchedStatements=true" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 | tee mysql.batchrewrite.log 




cp ~/jdbc/mysql-connector-j-8.0.31/mysql-connector-j-8.0.31.jar YCSB/lib







```
apt install postgresql-client-common
```


Some unofficial pacakgse from datagrip

https://hub.docker.com/r/datagrip/sybase

Guest user
SYBASE_USER=tester
SYBASE_PASSWORD=guest1234
SYBASE_DB=testdb
Admin user

SYBASE_USER=sa
SYBASE_PASSWORD=myPassword