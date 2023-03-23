
Download Oracle from OTN

cd OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh


## Oracle

### Oracle Express Edition

```bash
git clone https://github.com/oracle/docker-images oracle-docker-images
cd oracle-docker-images
cd OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -x -i

docker volume create oracle1
docker run -d \
    --name oracle \
    --network arcnet \
    -p 1521:1521 -p 5500:5500 \
    -e ORACLE_PWD=Passw0rd \
    -v oracle1:/opt/oracle/oradata \
    oracle/database:21.3.0-xe
```

```
alter session set "_ORACLE_SCRIPT"=true;

CREATE USER arcsrc IDENTIFIED BY Passw0rd;

grant CREATE SESSION, ALTER SESSION, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW, CREATE PROCEDURE, CREATE PUBLIC SYNONYM, CREATE ROLE, CREATE SEQUENCE, CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW, UNLIMITED TABLESPACE to arcsrc;
```

## X11

```bash
sudo apt-get install x11-xserver-utils
 docker run -it --rm -v ~/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY --network=host --name hammerdb tpcorg/hammerdb:oracle bash
```
