#!/usr/bin/env bash

# root connection to minio
mc alias set minio http://${DSTDB_HOST}:${DSTDB_PORT} ${DSTDB_ROOT}  ${DSTDB_PW}

# add arcdst user w/ read write
mc admin user add minio ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}
mc admin policy attach minio readwrite --user ${DSTDB_ARC_USER} 

# remove bucket.hostname from /etc/hosts
# sed: cannot rename /etc/hosts: Device or resource busy if directly changing /etc/hosts
cp /etc/hosts /tmp/etc_hosts.new
sed -i.bak "s/^.*[[:blank:]]\+${DSTDB_ARC_USER}.${DSTDB_HOST}.*\$//g" /tmp/etc_hosts.new
sudo cp /tmp/etc_hosts.new /etc/hosts
echo "Removed ${DSTDB_ARC_USER}.${DSTDB_HOST} from /etc/hosts"
diff /etc/hosts /tmp/etc_hosts.new.bak

exit 0