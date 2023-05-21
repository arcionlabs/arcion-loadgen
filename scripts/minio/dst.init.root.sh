#!/usr/bin/env bash

# root connection to minio
mc alias set minio http://minio:9000 ${DSTDB_ROOT}  ${DSTDB_PW}

# add arcdst user w/ read write
mc admin user add minio ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}
mc admin policy attach minio readwrite --user ${DSTDB_ARC_USER} 

# arcion requires bucket.hostname in dns
IP=$(arp -n $DSTDB_HOST arp -n minio | tail -n +2 | awk '{print $1}')
echo "Checking if $DSTDB_HOST with $IP is in /etc/hosts"
if [ ! -z "$IP" ]; then
    ETC_HOST=$(cat /etc/hosts | grep ^$IP )
    if [ -z "${ETC_HOST}" ]; then 
        echo "adding to /etc/hosts"
        sudo tee -a /etc/hosts <<< "$IP ${DSTDB_ARC_USER}.${DSTDB_HOST}"
    else
        echo "${DSTDB_ARC_USER}.${DSTDB_HOST} alrady in /etc/hosts"
    fi
else
    echo "$DSTDB_HOST IP not found"
    exit    
fi