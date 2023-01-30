

from https://github.com/akopytov/sysbench

```
sudo apt update
sudo apt install sysbench
```


```
CREATE TABLE sbtest1(
  id integer,
  k INTEGER DEFAULT '0' NOT NULL,
  c CHAR(120) DEFAULT '' NOT NULL,
  pad CHAR(60) DEFAULT '' NOT NULL,
  primary key (id)
);
```  

https://github.com/cockroachdb/docs/issues/4221

mysql
```
_sysb() { 
    sysbench \
    --threads=${_sysb_threads:-1} \
    --events=0 \
    --db-driver=mysql \
    --mysql-host=${_sysb_host:-127.0.0.1} \
    --mysql-port=${_sysb_port:-3306} \
    --mysql-user=${_sysb_user:-sbt} \
    --mysql-db=${_sysb_db:-sbt} \
    --delete_inserts=${_sysb_inserts:-0} \
    --index_updates=${_sysb_updates:-0} \
    --non_index_updates=${_sysb_non_index_updates:-0} \ 
    --table-size=${_sysb_table_size:-1222} \
    --db-ps-mode=disable \
    --report-interval=${_sysb_report_interval:-1} \
    --histogram=on --time=${_sysb_time:-60} \
    --debug=${_sysb_debug:-off} \
    --verbosity=${_sysb_verbosity:-3} \
    $* 
}
```

pg
```
sysb() { 
    sysbench \
    --threads=${_sysb_threads:-1} \
    --events=0 \
    --db-driver=mysql \
    --pgsql-host=${_sysb_host:-localhost} \
    --pgsql-port=${_sysb_port:-26257} \
    --pgsql-user=${_sysb_user:-root} \
    --pgsql-db=${_sysb_db:-defaultdb} \
    --delete_inserts=${_sysb_inserts:-0} \
    --index_updates=${_sysb_updates:-0} \
    --non_index_updates=${_sysb_non_index_updates:-0} \ 
    --table-size=${_sysb_table_size:-1222} \
    --db-ps-mode=disable \
    --report-interval=${_sysb_report_interval:-1} \
    --histogram=on --time=${_sysb_time:-60} \
    --debug=${_sysb_debug:-off} \
    --verbosity=${_sysb_verbosity:-3} \
    $* 
}
```

```
mysql -u sbt -d sbt -e "drop table if exists sbtest1"
_sysb oltp_read_write --auto_inc=off prepare
_sysb oltp_read_write --auto_inc=off run
_sysb select_random_points --auto_inc=off run
_sysb oltp_insert --auto_inc=off run
```