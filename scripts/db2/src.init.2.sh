#!/usr/bin/env bash

#!/usr/bin/env bash

. ~/sqllib/db2profile

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

echo "check for existing database setup"

db2 list database directory
if [ "$?" = "0" ]; then
    echo "database already setup"
fi

# Catalog the source Db2 database:
# note using the hostname as the nodename
#  db2 uncatalog node ${SRCDB_DB}; db2 terminate to redo
# node name cannot have dash (-) use shortname
db2 catalog tcpip node ${SRCDB_SHORTNAME} remote ${SRCDB_SHORTNAME} server ${SRCDB_PORT} 

db2 list node directory

# catalog the database name
#  db2 uncatalog database ${SRCDB_DB}; db2 terminate to redo
db2 catalog database ${SRCDB_DB} at node ${SRCDB_SHORTNAME}

db2 list database directory

# test the connection
db2 connect to ${SRCDB_DB} user ${SRCDB_ARC_USER} using ${SRCDB_ARC_PW}

