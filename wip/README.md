# Arcion with MySQL source and MySQL target databases
 

https://docs.singlestore.com/db/v7.8/en/deploy/singlestoredb-dev-image.html for singlestore
```
docker run --net mynet --name singlestore -i --init \
    -e LICENSE_KEY="$SINGLESTORE_LIC" \
    -e ROOT_PASSWORD="password" \
    -p 3306:3306 -p 8081:8080 \
    singlestore/cluster-in-a-box

docker start singlestore
```

- docker prep
```bash
docker pull arcionlabs/replicant-on-premises
docker pull mysql
docker pull postgres
docker pull imply/imply # mysql destination is not default allowed in GUI.  does not look like there is a way to set the username and password


docker network create mynet

docker volume create mysql1
docker volume create mysql2
docker volume create arcion1
docker volume create arcion_pg

```

- start pg for arcion
```bash
docker run --net mynet --name arcion_pg -p 54320:5432 -e POSTGRES_PASSWORD=password -d --restart unless-stopped -v arcion_pg:/var/lib/postgresql/data  postgres
```

- start arcion
  
more info at https://hub.docker.com/r/arcionlabs/replicant-on-premises

-p 8080	Allows HTTP access to the application
-v /config	Volume containing the replicant.lic license file, get your free 30-day trial license here
-v /data	Volume for data and configuration storage
[-v /libs	Volume for external JAR libraries to be used by Replicant]

-e DB_USERNAME=postgres
-e DB_DATABASE=postgres

Note:
there are no logs from `docker logs arcion1`
when wrong password is entered, invalid credential pop should be by the password not lower right that dispears after about 10 seconds 
arcion lab help on the lower right has 3 swimming dots
why start from snapshot wouldn't full be the most popular (full is the first option in docs https://docs.arcion.io/docs/running-replicant/#replicant-full-mode)
not sure the diff between replace and truncating (https://docs.arcion.io/docs/running-replicant/#write-modes-explained)
   --append-existing|--replace-existing|--truncate-existing
wrong id has the following message
  com.zaxxer.hikari.pool.HikariPool$PoolInitializationException: Failed to initialize pool: Could not connect to address=(host=mysql1)(port=3306)(type=master) : RSA public key is not available client side (option serverRsaPublicKeyFile not set)

the default docker has log_bin enabled  
mysql> show variables like "%log_bin%";
+---------------------------------+-----------------------------+
| Variable_name                   | Value                       |
+---------------------------------+-----------------------------+
| log_bin                         | ON                          |
| log_bin_basename                | /var/lib/mysql/binlog       |
| log_bin_index                   | /var/lib/mysql/binlog.index |
| log_bin_trust_function_creators | OFF                         |
| log_bin_use_v1_row_events       | OFF                         |
| sql_log_bin                     | ON                          |
+---------------------------------+-----------------------------+
mysql> SET GLOBAL binlog_format = 'ROW'
mysql> show variables like "%log_bin%";
+---------------------------------+-----------------------------+
| Variable_name                   | Value                       |
+---------------------------------+-----------------------------+
| log_bin                         | ON                          |
| log_bin_basename                | /var/lib/mysql/binlog       |
| log_bin_index                   | /var/lib/mysql/binlog.index |
| log_bin_trust_function_creators | OFF                         |
| log_bin_use_v1_row_events       | OFF                         |
| sql_log_bin                     | ON                          |
+---------------------------------+-----------------------------+

6 rows in set (0.08 sec)
mysql> show binary logs;
+---------------+-----------+-----------+
| Log_name      | File_size | Encrypted |
+---------------+-----------+-----------+
| binlog.000001 |   3032843 | No        |
| binlog.000002 |       180 | No        |
| binlog.000003 |      1423 | No        |
+---------------+-----------+-----------+
3 rows in set (0.01 sec)

after flush priv, the test connection fails.  works ok after retrying

what is url reachable 

sync connector 
  scchema must be available to continue tests
```

cd /Users/rslee/github/ycsb-ui/arcion
docker run --net mynet --name arcion1 -p 8080:8080 -e DB_HOST=arcion_pg -e DB_USERNAME=postgres -e DB_PASSWORD=password -e DB_DATABASE=postgres -d --restart unless-stopped -v `pwd`/config:/config -v arcion1:/data arcionlabs/replicant-on-premises:latest
```

- start mysql
```bash
docker run --net mynet --name mysql1 -p 33061:3306 -e MYSQL_ROOT_PASSWORD=password -d --restart unless-stopped -v mysql1:/var/lib/mysql  mysql:latest
docker run --net mynet --name mysql2 -p 33062:3306 -e MYSQL_ROOT_PASSWORD=password -d --restart unless-stopped -v mysql2:/var/lib/mysql  mysql:latest
```

- start imply
```
docker run --net mynet -p 8081-8110:8081-8110 -p 8200:8200 -p 9095:9095 -p 9097:9097 -p 9999:9999 -d --name imply imply/imply
```
- start arcion
```


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

- setup mysql accounts for ycsb and sysbench
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
// cannot limit to database.  has to be *.*
GRANT REPLICATION CLIENT ON *.* TO 'sbt'@'%';
GRANT REPLICATION SLAVE ON *.* TO 'sbt'@'%';

// setup heartbeat
CREATE TABLE sbt.REPLICATE_IO_CDC_HEARTBEAT(
  timestamp BIGINT NOT NULL,
  PRIMARY KEY(timestamp)
);

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
	ycsb_key int PRIMARY KEY,
	field0 TEXT, field1 TEXT,
	field2 TEXT, field3 TEXT,
	field4 TEXT, field5 TEXT,
	field6 TEXT, field7 TEXT,
	field8 TEXT, field9 TEXT
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