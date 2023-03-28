Instructions for mounting new Arcion binary and Script for development purposes.

# Swap out default Arcion binary

```bash
docker volume create arcion_22113017

- download from URL

ARCION_BIN_URL="https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-22.11.30.17.zip"

docker run -it --rm -v arcion_22113017:/arcion -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
cd /arcion;\
wget $ARCION_BIN_URL;\
unzip -q *.zip;\
mv replicant-cli/* .;\
rmdir replicant-cli/;\
chown -R 1000 .;\
'

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

```bash
git clone https://github.com/robert-s-lee/arcion-demo
cd arcion-demo/scripts
mkdir -p ~/arcion-demo/logs
mkdir -p ~/arcion-demo/configs
docker run -d --name arcion-demo \
    --network arcnet \
    -e ARCION_LICENSE="${ARCION_LICENSE}" \
    -e LANG=C.UTF-8 \
    -p 7681:7681 \
    -v `pwd`/scripts:/scripts \
    -v `pwd`/data/:/arcion/data/ \
    robertslee/arcdemo
```

    -v `~/arcion-demo/configs`:/tmp/arcion \




manual setup

```bash
unset SRCDB_HOST SRCDB_DIR DSTDB_HOST DSTDB_DIR REPL_TYPE; ./menu.sh
```

