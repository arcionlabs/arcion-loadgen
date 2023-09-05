#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/jdbc_cli.sh

# MARIADB_VERSION
downloadMariadbBinlogger() {

if [ -z "$MARIADB_VERSION" ]; then
    echo -n "MariaDB:binlog: running select version(): "
    export MARIADB_VERSION=$(
        echo "select version(); -m csv" | jdbc_root_cli_src "${JSQSH_CSV}" | awk -F'-' '{print $1}'
    )
    echo "${MARIADB_VERSION}"
fi

if [ -z "$MARIADB_VERSION" ]; then
    echo "MARIADB_VERSION not determined"
    return 1
fi

echo -n "MariaDB:binlog: checking -d ${MARIADB_DIR}/${MARIADB_VERSION}: "
if [ -d ${MARIADB_DIR}/${MARIADB_VERSION} ]; then     
    echo "found. skip binlog install"
else
    # https://mariadb.com/kb/en/mariadb-package-repository-setup-and-usage/
    echo "MariaDB:binlog: downloading but not install: "
    # exit on any failure
    set -e
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=$MARIADB_VERSION
    cd ${MARIADB_DIR}
    mkdir ${MARIADB_VERSION}
    cd ${MARIADB_VERSION}
    # on 10.x binlogger is on the server package
    # on 11.x binlogger is on the client package
    apt-get download mariadb-server mariadb-client
    ls *.deb | xargs -I % dpkg -x % .
    ls *.deb > README.txt
    rm *.deb 
fi
}

