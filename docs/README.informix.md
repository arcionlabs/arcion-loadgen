
more info at https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md

```
docker run -d --name ifx -h ifx \
    -p 9088:9088 \
      -p 9089:9089 \
      -p 27017:27017 \
      -p 27018:27018 \
      -p 27883:27883 \
      -e LICENSE=accept \
      ibmcom/informix-developer-database:latest
```      

https://informix-technology.blogspot.com/2009/04/informix-authentication-and-connections.html

https://www.ics.uci.edu/~dbclass/ics184/htmls/Informix_guide.html

create user https://www.ibm.com/docs/en/informix-servers/12.10?topic=statements-create-user-statement-unix-linux

docker exec -t ifx
dbaccess
onstat


cd
PATH=/opt/ibm/informix/bin:$PATH
dbaccessdemo

echo "create user arcsrc with password 'Passw0rd';" | dbaccess


https://www.ibm.com/docs/en/informix-servers/12.10?topic=linux-creating-database-server-users-unix

onmode -wf USERMAPPING=BASIC
sudo bash
useradd -d /home/ifxsurr -s /bin/false ifxsurr
mkdir /etc/informix
echo "USERS:ifxsurr" > /etc/informix/allowed.surrogates
chown root:root /etc/informix/allowed.surrogates
exit


dbaccess - -
database sysuser;
CREATE DEFAULT USER WITH PROPERTIES USER 'guest';

CREATE USER arcdst WITH PASSWORD Passw0rd;
