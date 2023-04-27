
more info at https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md

Default root id/password = informix/in4mix

```bash
docker run -d \
  --name informix \
  --network arcnet \
  -p :9088 \
  -p :9089 \
  -p :27017 \
  -p :27018 \
  -p :27883 \
  -e LICENSE=accept \
  -e RUN_FILE_POST_INIT=informix.root.sh \
  -v $ARCDEMO_DIR/docs/informix/informix.root.sh:/opt/ibm/config/informix.root.sh \
  ibmcom/informix-developer-database:latest
```      

```
docker exec -it informix sh -c 
onmode -wf USERMAPPING=BASIC
[ ! -d /etc/informix ] && sudo mkdir -p /etc/informix
# allow remote login for users
sudo echo "arcion-demo.arcnet" >>  $INFORMIXDIR/etc/hosts.equiv
# create host user and set database password
# create utf8 compitable database
# export GL_USEGLU=1

while read -r line; do
  user=$( echo $line | awk '{print $1}')
  password=$( echo $line | awk '{print $2}')
  echo $user >> ~/.rhosts 
  sudo useradd -d /home/$user -s /bin/false $user
  sudo tee -a /etc/informix/allowed.surrogates <<< "USER:$user"
  echo "create user $user with password '$password';" | dbaccess
  echo "create database IF NOT EXISTS $user with LOG;" | dbaccess
  echo "grant resource to $user;" | dbaccess $user
  echo "grant connect to $user;" | dbaccess $user
done << EOF
arcsrc Passw0rd
arcdst Passw0rd
EOF
# make the users available
onmode -cache surrogates
#loading cdc prerequisite
dbaccess - $INFORMIXDIR/etc/syscdcv1.sql
echo "CDC prerequisite sql loaded..."
```
