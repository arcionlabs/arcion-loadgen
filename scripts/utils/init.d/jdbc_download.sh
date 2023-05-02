#!/usr/bin/env bash

# download oracle jdbc if not there
if [ ! -f /libs/ojdbc8.jar ]; then
    pushd /libs
    curl -O --location https://download.oracle.com/otn-pub/otn_software/jdbc/1815/ojdbc8.jar
    popd
else
    echo "/libs/ojdbc8.jar found"
fi

# download GoogleBigQuery jdbc if not there
if [ ! -f /libs/GoogleBigQueryJDBC42.jar ]; then
    pushd /libs
    curl -O --location https://storage.googleapis.com/simba-bq-release/jdbc/SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip
    unzip -q SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip GoogleBigQueryJDBC42.jar
    rm SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip
    popd
else
    echo "/libs/GoogleBigQueryJDBC42.jar found"
fi

# download log4j
if [ ! -f /libs/log4j-1.2.17.jar ]; then
    pushd /libs
    curl -O --location https://repo1.maven.org/maven2/log4j/log4j/1.2.17/log4j-1.2.17.jar
    popd
else
    echo "/libs/log4j-1.2.17.jar found"
fi

# copy 
for f in $(find /libs/*); do
  echo cp $f $ARCION_HOME/lib/.
  cp $f $ARCION_HOME/lib/.
done

# fix the issue with ojdbc
# WARNING: Error while registering Oracle JDBC Diagnosability MBean.
# As default, JRE use the default properties file in JRE_HOME\lib\logging.properties, so edit the file and adding this info:
# oracle.jdbc.level=OFF

for d in $( find /usr/lib/jvm -name lib -type d ); do
    echo $d
    sudo tee -a ${d}/lib/logging.properties <<< "oracle.jdbc.level=OFF"
done
