
Start demo


```bash
cd arcion-demo
ARCION_LICENSE=$(cat ~/Downloads/replicant.lic | base64)
docker run -d \
    --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE=${ARCION_LICENSE} \
    -e ARCION_HOME=/arcion \
    -e SCRIPTS_DIR=/scripts \
    -e SRCDB_HOST=mysql-db \
    -e DSTDB_HOST=mysql-db-2 \
    -e SRCDB_TYPE=mysql \
    -e DSTDB_TYPE=mysql \
    -p :7681 \
    -v `pwd`/scripts:/scripts \
    robertslee/sybench

    -v `pwd`/replicant-cli:/arcion \


```
unset SRCDB_HOST SRCDB_TYPE DSTDB_HOST DSTDB_TYPE REPL_TYPE; ./menu.sh

SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=full ./menu.sh
SRCDB_HOST=mysql-db SRCDB_TYPE=mysql DSTDB_HOST=mysql-db-2 DSTDB_TYPE=mysql REPL_TYPE=real-time ./menu.sh


SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=snapshot ./menu.sh
SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=full ./menu.sh
SRCDB_HOST=pg-db SRCDB_TYPE=postgres DSTDB_HOST=pg-db-2 DSTDB_TYPE=postgres REPL_TYPE=real-time ./menu.sh


```
ALTER TABLE usertable ADD COLUMN ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP after FIELD9;
ALTER TABLE usertable DROP COLUMN ts;
```