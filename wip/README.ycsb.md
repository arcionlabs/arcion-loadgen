
CockroachDB
cockroach sql --insecure -e "truncate usertable"

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1:26257/defaultdb?autoReconnect=true&sslmode=disable&ssl=false" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=false -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar >  cockraochdb.nobatch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1:26257/defaultdb?autoReconnect=true&sslmode=disable&ssl=false" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar > cockraochdb.batch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1:26257/defaultdb?autoReconnect=true&sslmode=disable&ssl=false&reWriteBatchedInserts=true" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar  > cockraochdb.batchrewrite.log
MariaDB
mysql -u root -D ycsb -e "truncate usertable"

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://localhost/ycsb" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=false -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/mysql-connector-java-5.1.47.jar > mariadb.nobatch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://localhost/ycsb" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/mysql-connector-java-5.1.47.jar > mariadb.batch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://localhost/ycsb?rewriteBatchedStatements=true" -p db.user=root -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/mysql-connector-java-5.1.47.jar > mariadb.batchrewrite.log 
Postgres
psql -U postgres -c "truncate usertable"

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1/?autoReconnect=true&sslmode=disable&ssl=false" -p db.user=postgres -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=false -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar > postgres.nobatch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1/?autoReconnect=true&sslmode=disable&ssl=false" -p db.user=postgres -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar > postgres.batch.log

bin/ycsb load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver -p db.url="jdbc:postgresql://127.0.0.1/?autoReconnect=true&sslmode=disable&ssl=false&reWriteBatchedInserts=true" -p db.user=postgres -p db.passwd="" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=100000 -cp ~/Downloads/postgresql-42.2.4.jar > postgres.batchrewrite.log
Logs of each runs below: