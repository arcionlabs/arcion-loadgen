#!/usr/bin/env bash

echo "checking existence of /opt/oracle"
if [ -d /opt/oracle ]; then
    echo "found."
else
    if mkdir /opt/oracle; then
        echo "/opt/oracle created."
    else
        echo "Error: mkdir /opt/oracle exited with $?." 
        exit 1
    fi
fi

echo "checking write for /opt/oracle"
if [ -w /opt/oracle ]; then
    echo "writable."
else
    if sudo chown -R arcion:arcion /opt/oracle; then
        echo "sudo chown -R arcion:arcion /opt/oracle."
    else
        echo "Error: sudo chown -R arcion:arcion /opt/oracle exited with $?." 
        exit 1
    fi
fi

# https://docs.arcion.io/docs/source-setup/oracle/native-export/

echo "checking for existance of /opt/oracle/bin" 
if [ ! -d "/opt/oracle/bin" ]; then
    set -x 
    mkdir -p /opt/oracle
    cd /opt/oracle
    wget -q https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    unzip -q instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    mv instantclient_21_6 bin
    rm instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
    set +x
fi

echo "checking for existance of /opt/oracle/lib" 
if [ ! -d "/opt/oracle/lib" ]; then
    set -x 
    mkdir -p /opt/oracle
    cd /opt/oracle
    wget -q https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    unzip -q instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    mv instantclient_21_6 lib
    rm  instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
    set +x
fi