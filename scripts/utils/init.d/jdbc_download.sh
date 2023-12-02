#!/usr/bin/env bash

# vertica
if [ ! -f /opt/stage/libs/vertica-jdbc-23.4.0-0.jar ]; then
    pushd /opt/stage/libs >/dev/null
    wget https://repo1.maven.org/maven2/com/vertica/jdbc/vertica-jdbc/23.4.0-0/vertica-jdbc-23.4.0-0.jar
    popd >/dev/null
else
    echo "vertica /opt/stage/libs/vertica-jdbc-23.4.0-0.jar found"
fi

# db2
if [ ! -f /opt/stage/libs/jcc-11.5.9.0.jar ]; then
    pushd /opt/stage/libs >/dev/null
    wget https://repo1.maven.org/maven2/com/ibm/db2/jcc/11.5.9.0/jcc-11.5.9.0.jar
    popd >/dev/null
else
    echo "db2 /opt/stage/libs/jcc-11.5.9.0.jar found"
fi

#informix
if [ ! -f /opt/stage/libs/jdbc-4.50.10.jar ]; then
    pushd /opt/stage/libs >/dev/null
    wget https://repo1.maven.org/maven2/com/ibm/informix/jdbc/4.50.10/jdbc-4.50.10.jar
    popd >/dev/null
else
    echo "informix /opt/stage/libs/jdbc-4.50.10.jar found"
fi

# download oracle jdbc if not there
if [ ! -f /opt/stage/libs/ojdbc8.jar ]; then
    pushd /opt/stage/libs >/dev/null
    curl -O --location https://download.oracle.com/otn-pub/otn_software/jdbc/1815/ojdbc8.jar
    popd >/dev/null
else
    echo "oracle /opt/stage/libs/ojdbc8.jar found"
fi

# download GoogleBigQuery jdbc if not there
if [ ! -f /opt/stage/libs/GoogleBigQueryJDBC42.jar ]; then
    pushd /opt/stage/libs >/dev/null
    curl -O --location https://storage.googleapis.com/simba-bq-release/jdbc/SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip
    unzip -q SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip GoogleBigQueryJDBC42.jar
    rm SimbaJDBCDriverforGoogleBigQuery42_1.2.25.1029.zip
    popd >/dev/null
else
    echo "google big query /opt/stage/libs/GoogleBigQueryJDBC42.jar found"
fi

# deltalake
if [ ! -f /opt/stage/libs/SparkJDBC42.jar ]; then
    pushd /opt/stage/libs >/dev/null
    wget https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/jdbc/2.6.22/SimbaSparkJDBC42-2.6.22.1040.zip
    unzip -q SimbaSparkJDBC42-2.6.22.1040.zip
    rm SimbaSparkJDBC42-2.6.22.1040.zip
    popd >/dev/null
else
    echo "deltalake /opt/stage/libs/SparkJDBC42.jar found"
fi

# lakehouse (unity catalog)
if [ ! -f /opt/stage/libs/DatabricksJDBC42.jar ]; then
    pushd /opt/stage/libs >/dev/null
    wget https://repo1.maven.org/maven2/com/databricks/databricks-jdbc/2.6.34/databricks-jdbc-2.6.34.jar
    mv databricks-jdbc-2.6.34.jar DatabricksJDBC42.jar
    popd >/dev/null
else
    echo "lakehouse  /opt/stage/libs/DatabricksJDBC42.jar found"
fi

# download log4j
if [ ! -f /opt/stage/libs/log4j-1.2.17.jar ]; then
    pushd /opt/stage/libs >/dev/null
    curl -O --location https://repo1.maven.org/maven2/log4j/log4j/1.2.17/log4j-1.2.17.jar
    popd >/dev/null
else
    echo "log4j /opt/stage/libs/log4j-1.2.17.jar found"
fi

# copy 
for f in $(find /opt/stage/libs/*.jar); do
  echo cp $f $ARCION_HOME/lib/.
  cp $f $ARCION_HOME/lib/.
done

# fix the issue with ojdbc
# WARNING: Error while registering Oracle JDBC Diagnosability MBean.
# As default, JRE use the default properties file in JRE_HOME\lib\logging.properties, so edit the file and adding this info:
# oracle.jdbc.level=OFF

for d in $( find /usr/lib/jvm -name lib -type d ); do
    echo $d
    sudo tee -a ${d}/logging.properties <<< "oracle.jdbc.level=OFF"
done
