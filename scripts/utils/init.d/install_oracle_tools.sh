#!/usr/bin/env bash

# https://docs.arcion.io/docs/source-setup/oracle/native-export/

echo "checking for existance of /opt/oracle/bin" 
if [ ! -d "/opt/oracle/bin" ]; then
    set -x 
    mkdir /opt/oracle
    cd /opt/oracle
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    unzip -q instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    mv instantclient_21_6 bin
    rm instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    set +x
fi

echo "checking for existance of /opt/oracle/lib" 
if [ ! -d "/opt/oracle/lib" ]; then
    set -x 
    mkdir /opt/oracle
    wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    unzip -q instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    mv instantclient_21_6 lib
    rm  instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    set +x
fi