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
# https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html
# https://www.oracle.com/database/technologies/instant-client/linux-arm-aarch64-downloads.html

machine_hardware=$(uname -m)

echo "checking for existance of /opt/oracle/bin" 
if [ -d "/opt/oracle/bin" ]; then
    echo "/opt/oracle/bin already setup. skipping"
else
    mkdir -p /opt/oracle
    cd /opt/oracle
    case "${machine_hardware}" in 
    x86_64)
        wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
        unzip -q instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
        mv instantclient_21_6 bin
        rm instantclient-tools-linux.x64-21.6.0.0.0dbru.zip
        ;;
    aarch64)
        wget https://download.oracle.com/otn_software/linux/instantclient/1919000/instantclient-tools-linux.arm64-19.19.0.0.0dbru.zip
        unzip -q instantclient-tools-linux.arm64-19.19.0.0.0dbru.zip
        mv instantclient_19_19 bin
        rm instantclient-tools-linux.arm64-19.19.0.0.0dbru.zip
        ;;
    *)
        echo "Warning: ${machine_hardware} not handled for oracle client install"
        ;;
    esac
fi

echo "checking for existance of /opt/oracle/lib" 
if [ -d "/opt/oracle/lib" ]; then
    echo "/opt/oracle/lib already setup. skipping"
else
    mkdir -p /opt/oracle
    cd /opt/oracle
    case "${machine_hardware}" in 
    x86_64)
        wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
        unzip -q instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
        mv instantclient_21_6 lib
        rm  instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
        ;;
      aarch64)
        wget https://download.oracle.com/otn_software/linux/instantclient/1919000/instantclient-basic-linux.arm64-19.19.0.0.0dbru.zip
        unzip -q instantclient-basic-linux.arm64-19.19.0.0.0dbru.zip
        mv instantclient_19_19 lib
        rm instantclient-basic-linux.arm64-19.19.0.0.0dbru.zip
        ;;
    *)
        echo "Warning: ${machine_hardware} not handled for oracle client install"
        ;;
    esac      
fi