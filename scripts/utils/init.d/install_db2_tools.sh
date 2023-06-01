#!/usr/bin/env bash

echo "checking for existance of /opt/stage/libs/v11.5.4_linuxx64_client.tar.gz"

if [ -f "/opt/stage/libs/v11.5.4_linuxx64_client.tar.gz" ]; then
    echo "found"
else
    echo "not found.  skipping db2 setup"
    exit 0
fi

echo "checking prior setup of ~/sqllib"
if [ -d ~/sqllib ]; then
    echo "found.  skipping db2 setup"
    exit 0
fi

# required libs for db2 for ubuntu

# https://docs.arcion.io/docs/source-setup/db2/db2_native_luw/
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y file
sudo apt-get install -y libaio1 libstdc++6:i386 libpam0g:i386
sudo apt-get install -y binutils

# install on the machine where thet setup is run
# not required if using response file
sudo apt-get install -y libxrender1
# https://www.ibm.com/support/pages/unsatisfiedlinkerror-cannot-open-shared-object-file-libxtstso6
sudo apt-get install -y libxtst-dev

# setup db2 client at ~sqllib
mkdir /tmp/db2.$$
cd /tmp/db2.$$
gzip -dc /opt/stage/libs/v11.5.4_linuxx64_client.tar.gz | tar -xvf -
cd client
./db2setup -r $SCRIPTS_DIR/utils/init.d/db2client_nr.rsp

# remove temp files
rm -rf /tmp/db2.$$
