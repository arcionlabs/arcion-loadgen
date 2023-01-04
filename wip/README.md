# Arcion with MySQL source and MySQL target databases
 

- docker prep
```bash
docker pull arcionlabs/replicant-on-premises
docker pull mysql
docker pull postgres

docker network create mynet

docker volume create mysql1
docker volume create mysql2
docker volume create arcion1
docker volume create arcion_pg

```

- start pg for arcion
```bash
docker run --net mynet --name arcion_pg -p 54320:5432 -e POSTGRES_PASSWORD=password -d postgres --restart unless-stopped -v arcion_pg:/var/lib/postgresql/data postgres
```

- start mysql
```bash
docker run --net mynet --name mysql1 -p 33061:3306 -e MYSQL_ROOT_PASSWORD=password -d --restart unless-stopped -v mysql1:/var/lib/mysql  mysql:latest
docker run --net mynet --name mysql2 -p 33062:3306 -e MYSQL_ROOT_PASSWORD=password -d --restart unless-stopped -v mysql2:/var/lib/mysql  mysql:latest

# check status of the containers
docker logs mysql1
docker logs mysql2
docker ps --filter name=mysql
```

- start arcion
```
./bin/replicant full conf/conn/source_database_name_src.yaml \
conf/conn/target_database_name.yaml \
--extractor conf/src/source_database_name.yaml \
--filter filter/source_database_name_filter.yaml

```

- create YCSB user account
```
docker run --net mynet -it --rm mysql mysql -hmysql -uroot -ppassword
// enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';
// check the list of existing users accounts
SELECT User, Host FROM mysql.user;
// create ycsb user account
CREATE USER IF NOT EXISTS 'ycsb'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'ycsb'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON ycsb.* to 'ycsb'@'%';
GRANT ALL ON ycsb.* to 'ycsb'@'localhost';

// create sysbench user account
CREATE USER IF NOT EXISTS 'sbt'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'sbt'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON sbt.* to 'sbt'@'%';
GRANT ALL ON sbt.* to 'sbt'@'localhost';
// flush
FLUSH PRIVILEGES;
```

- to see the SQL statements for the test
```
select convert(a.argument using utf8) from mysql.general_log a where a.command_type in ('Query','Execute');

```

- create ycsb database and usertable
```
docker run --net mynet -it --rm mysql mysql -hmysql -uycsb -ppassword
CREATE database ycsb;
USE ycsb;
CREATE TABLE usertable (
	YCSB_KEY VARCHAR(255) PRIMARY KEY,
	FIELD0 TEXT, FIELD1 TEXT,
	FIELD2 TEXT, FIELD3 TEXT,
	FIELD4 TEXT, FIELD5 TEXT,
	FIELD6 TEXT, FIELD7 TEXT,
	FIELD8 TEXT, FIELD9 TEXT
);
```

- create sbt database
```
docker run --net mynet -it --rm mysql mysql -hmysql -usbt -ppassword
CREATE database sbt;
USE sbt;
```

- download mysql jdbc driver
```
mkdir jdbc
cd jdbc
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.31.tar.gz
gzip -d -c mysql-connector-j-8.0.31.tar.gz | tar -xvf -
```

- alias for load generaor docker 
```
d(){docker run --net mynet --rm -it ycsb:0.17.0 "$@"}
```

```
mysql -u ycsb -D ycsb -ppassword -hmysql -e "truncate usertable" 
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://mysql/ycsb" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=false -p db.batchsize=1000 -p recordcount=100000 | tee mysql.nobatch.log
mysql -u ycsb -D ycsb -ppassword -hmysql -e "select count(*) from usertable;" 


mysql -u ycsb -D ycsb -ppassword -hmysql -e "truncate usertable" 
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://mysql/ycsb" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000  | tee mysql.batch.log

mysql -u ycsb -D ycsb -ppassword -hmysql -e "truncate usertable" 
bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://mysql/ycsb?rewriteBatchedStatements=true" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 | tee mysql.batchrewrite.log 










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