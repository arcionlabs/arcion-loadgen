#!/usr/bin/env bash

# required libs for db2 for ubuntu
db2_ubuntu_pkg_install() {

    # https://docs.arcion.io/docs/source-setup/db2/db2_native_luw/
    sudo dpkg --add-architecture i386
    #sudo apt-get update
    sudo apt-get install -y file
    sudo apt-get install -y libaio1 libstdc++6:i386 libpam0g:i386
    sudo apt-get install -y binutils

    # install on the machine where thet setup is run
    # not required if using response file
    sudo apt-get install -y libxrender1
    # https://www.ibm.com/support/pages/unsatisfiedlinkerror-cannot-open-shared-object-file-libxtstso6
    sudo apt-get install -y libxtst-dev
}

# if the container was remove and recreated, then package would be missing
# however, sqllib would still be there. check and install just in case
echo "checking db2 ubuntu packages"
db2_ubuntu_pkg_install

echo "checking existence of ~/sqllib"
if [ -d ~/sqllib ]; then
    echo "found."
else
    if mkdir ~/sqllib; then
        echo "~/sqllib created."
    else
        echo "Error: mkdir ~/sqllib exited with $?." 
        exit 1
    fi
fi

echo "checking prior setup of ~/sqllib/bin/db2"
if [ -x ~/sqllib/bin/db2 ]; then
    echo "~/sqllib/bin/db2 found.  skipping db2 setup"
    exit 0
else
    echo "~/sqllib/bin/db2 not found. will attempt setup"
fi

echo "checking write for ~/sqllib"
if [ -w ~/sqllib ]; then
    echo "writable."
else
    if sudo chown -R arcion:arcion ~/sqllib; then
        echo "sudo chown -R arcion:arcion ~/sqllib."
    else
        echo "Error: sudo chown -R arcion:arcion ~/sqllib exited with $?." 
        exit 1
    fi
fi

echo "checking for existance of /opt/stage/libs/v11.5.4_linuxx64_client.tar.gz"

if [ -f "/opt/stage/libs/v11.5.4_linuxx64_client.tar.gz" ]; then
    echo "found"
else
    echo "not found.  skipping db2 setup"
    exit 0
fi

# setup db2 client at ~sqllib
mkdir /tmp/db2.$$
cd /tmp/db2.$$
gzip -dc /opt/stage/libs/v11.5.4_linuxx64_client.tar.gz | tar -xvf -
cd client
./db2setup -r $SCRIPTS_DIR/utils/init.d/db2client_nr.rsp

# remove temp files
rm -rf /tmp/db2.$$
