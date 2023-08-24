CREATE USER ${SRCDB_ARC_USER} PASSWORD '${SRCDB_ARC_PW}';
alter user ${SRCDB_ARC_USER} replication;
create database ${SRCDB_ARC_USER};
ALTER database ${SRCDB_ARC_USER} owner to ${SRCDB_ARC_USER};
grant all privileges on database ${SRCDB_ARC_USER} to ${SRCDB_ARC_USER};