CREATE USER ${DSTDB_ARC_USER} PASSWORD '${DSTDB_ARC_PW}';
create database ${DSTDB_ARC_USER};
ALTER database ${DSTDB_ARC_USER} owner to ${DSTDB_ARC_USER};
grant all privileges on database ${DSTDB_ARC_USER} to ${DSTDB_ARC_USER};