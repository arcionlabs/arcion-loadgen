Instructions for mounting new Arcion binary and Script for development purposes.

```bash
docker run -d \
    --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -p 7681:7681 \
    -v `pwd`/scripts:/scripts \
    robertslee/sybench
```



manual setup

```bash
unset SRCDB_HOST SRCDB_TYPE DSTDB_HOST DSTDB_TYPE REPL_TYPE; ./menu.sh
```

The follow works

mysql to mysql, pg, s2
cockroach (snpashot) to mysql, pg, s2
```bash
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=full ./menu.sh
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=real-time ./menu.sh

SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=snapshot ./menu.sh


SRCDB_HOST=roach1 SRCDB_TYPE=cockroach DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=roach1 SRCDB_TYPE=cockroach DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=snapshot ./menu.sh

```

The following do not work

```bash
SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=full ./menu.sh
SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=real-time ./menu.sh

SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=roach1 DSTDB_TYPE=cockroach REPL_TYPE=snapshot ./menu.sh
```

```
ALTER TABLE usertable ADD COLUMN ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP after FIELD9;
ALTER TABLE usertable DROP COLUMN ts;
```