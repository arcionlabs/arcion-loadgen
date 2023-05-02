Instructions for mounting new Arcion binary and Script for development purposes.

# Swap out default Arcion binary

```bash

- set the download URL

```bash
ARCION_BIN_URL="https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-22.11.30.17.zip"
ARCION_BIN_URL=https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.01.15.zip
ARCION_BIN_URL=https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.31.16.zip
```

- set the docker volume name

generate the docker volume with the binary

```bash
function create_arcion_bin_volume () {
    local ARCION_BIN_URL=$1
    [ -z "${1}" ] && echo "please enter URL as param." && return 1
    local VER=$(echo $ARCION_BIN_URL | sed 's/.*cli-\(.*\)\.zip$/\1/' | sed 's/\.//g')
    docker volume create arcion-bin-$VER
    docker run -it --rm -v arcion-bin-$VER:/arcion -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
    cd /arcion;\
    wget $ARCION_BIN_URL;\
    unzip -q *.zip;\
    mv replicant-cli/* .;\
    rm -rf replicant-cli/;\
    rm *.zip;\
    chown -R 1000 .;\
    ls\
    '
}

function create_arcion_bin_volume2 () {
    local ARCION_BIN_URL=$1
    [ -z "${1}" ] && echo "please enter URL as param." && return 1
    local VER=$(echo $ARCION_BIN_URL | sed 's/.*cli-\(.*\)\.zip$/\1/' | sed 's/\.//g')
    docker volume create arcion-bin-$VER
    docker run -it --rm -v arcion-bin-$VER:/ -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
    cd /;\
    wget $ARCION_BIN_URL;\
    unzip -q *.zip;\
    rm *.zip;\
    chown -R 1000 .;\
    ls\
    '
}

```

create_arcion_bin_volume https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.31.16.zip

create_arcion_bin_volume https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.01.15.zip

- stage from local file

docker volume create arcion_bin_ce_812

ARCION_BIN_ZIP=replicant-cli-CE-812.zip
docker run -it --rm -v arcion_bin_ce_812:/arcion -v ~/Downloads:/downloads -e ARCION_BIN_ZIP="$ARCION_BIN_ZIP" alpine sh -c '\
cd /arcion;\
unzip -q /downloads/$ARCION_BIN_ZIP;\
mkdir data;\
mkdir run;\
[ -d replicant-cli ] && mv replicant-cli/* && rmdir replicant-cli/;\
chown -R 1000 .;\
'

# Swap out volume and scripts

```
docker pull arcionlabs/replicant-on-premises:test
docker run -d \
    --name arcion-ui-test \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -e DB_HOST=arcion-metadata-test \
    -e DB_PORT=5432 \
    -e DB_DATABASE=arcion \
    -e DB_USERNAME=arcion \
    -e DB_PASSWORD=Passw0rd \
    -p :8080 \
    -v `pwd`/arcion-ui/data:/data \
    -v `pwd`/arcion-ui/config:/config \
    -v `pwd`/arcion-ui/libs:/libs \
    arcionlabs/replicant-on-premises:test
```    

```bash
git clone https://github.com/robert-s-lee/arcion-demo
cd arcion-demo/scripts
mkdir -p ~/arcion-demo/logs
mkdir -p ~/arcion-demo/configs
mkdir -p ~/arcion-demo/data
docker run -d --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -e LANG=C.UTF-8 \
    -p 7681:7681 \
    -v `pwd`/scripts:/scripts \
    -v `pwd`/arcion-demo/data/:/arcion/data/ \
    robertslee/arcdemo
```

    -v `~/arcion-demo/configs`:/tmp/arcion \




manual setup

```bash
unset SRCDB_HOST SRCDB_DIR DSTDB_HOST DSTDB_DIR REPL_TYPE; ./menu.sh
```

