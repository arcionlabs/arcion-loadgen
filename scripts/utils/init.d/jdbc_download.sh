#!/usr/bin/env bash

if [ ! -f $ARCION_HOME/lib/ojdbc8.jar ]; then
    pushd $ARCION_HOME/lib
    curl -O --location https://download.oracle.com/otn-pub/otn_software/jdbc/1815/ojdbc8.jar
    popd
fi

# fix the issue with ojdbc
# WARNING: Error while registering Oracle JDBC Diagnosability MBean.
# As default, JRE use the default properties file in JRE_HOME\lib\logging.properties, so edit the file and adding this info:
# oracle.jdbc.level=OFF

for d in $( find /usr/lib/jvm -name lib -type d ); do
    echo $d
    sudo tee -a ${d}/lib/logging.properties <<< "oracle.jdbc.level=OFF"
done
