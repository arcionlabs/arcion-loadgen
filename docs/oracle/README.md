
Download Oracle from OTN

## User
User setup in PDB
https://oracle-base.com/articles/12c/multitenant-manage-users-and-privileges-for-cdb-and-pdb-12cr1


```
-- Create the common user using the CONTAINER clause.
CREATE USER c##arcsrc IDENTIFIED BY Passw0rd CONTAINER=ALL;
GRANT CREATE SESSION TO c##arcsrc CONTAINER=ALL;

-- list pdbs
select * from DBA_PDBS order by pdb_id;

```




cd OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh


## Oracle EE

```bash
./buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'
```

-e INIT_SGA_SIZE=<your database SGA memory in MB> \
-e INIT_PGA_SIZE=<your database PGA memory in MB> \
-e INIT_CPU_COUNT=<cpu_count init-parameter> \
-e INIT_PROCESSES=<processes init-parameter> \
-e ORACLE_CHARACTERSET=<your character set> \
-e ENABLE_TCPS=true \

```
docker volume create oracle-ee-19-3-0
docker run -d \
    --name oraee \
    --network arcnet \
    -p :1521 \
    -p :5500 \
    -p :2484 \
    -e ORACLE_SID=orcl \
    -e ORACLE_PDB=orclpdb1 \
    -e ORACLE_PWD=Passw0rd \
    -e ORACLE_EDITION=enterprise \
    -e ENABLE_ARCHIVELOG=true \
    -e AUTO_MEM_CALCULATION=false \
    -v oracle-ee-19-3-0:/opt/oracle/oradata \
    oracle/database:19.3.0-ee
```
### Oracle Express Edition

SID cannot be changed

Default root id/password = Passw0rd

jsqsh --driver oracle --server oracle --port 1521 --user system --password Passw0rd --database XE

```bash
git clone https://github.com/oracle/docker-images oracle-docker-images
cd oracle-docker-images
cd OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -x -i

docker volume create oracle1
docker run -d \
    --name oraxe \
    --network arcnet \
    -p :1521 \
    -p :5500 \
    -e ORACLE_PWD=Passw0rd \
    -v oracle1:/opt/oracle/oradata \
    oracle/database:21.3.0-xe
```

sqlplus sys/<your password>@//localhost:1521/XE as sysdba
sqlplus system/<your password>@//localhost:1521/XE
sqlplus pdbadmin/<your password>@//localhost:1521/XEPDB1

```
CREATE USER c##arcsrc IDENTIFIED BY Passw0rd;

grant CREATE SESSION, ALTER SESSION, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW, CREATE PROCEDURE, CREATE PUBLIC SYNONYM, CREATE ROLE, CREATE SEQUENCE, CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW, UNLIMITED TABLESPACE to arcsrc;

CREATE USER arcdst IDENTIFIED BY Passw0rd;

grant CREATE SESSION, ALTER SESSION, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW, CREATE PROCEDURE, CREATE PUBLIC SYNONYM, CREATE ROLE, CREATE SEQUENCE, CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW, UNLIMITED TABLESPACE to arcdst;

```

