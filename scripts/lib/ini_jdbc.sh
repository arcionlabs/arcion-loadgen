#!/usr/bin/env bash

# NOTE: dbname=usernamne. "##DB_USER_NAME##" must be changed to actual by the script as 
export SRCDB_JDBC_DRIVER
export SRCDB_JDBC_URL
export SRCDB_JDBC_URL_IDPW
export SRCDB_JDBC_URL_BENCHBASE
export SRCDB_ROOT_URL

export DSTDB_JDBC_DRIVER
export DSTDB_JDBC_URL
export DSTDB_JDBC_URL_IDPW
export DSTDB_JDBC_URL_BENCHBASE
export DSTDB_ROOT_URL

export SRCDB_YCSB_DRIVER
export DSTDB_YCSB_DRIVER
export SRCDB_JSQSH_DRIVER
export DSTDB_JSQSH_DRIVER

export SRCDB_JDBC_NO_REWRITE
export SRCDB_JDBC_REWRITE
export DSTDB_JDBC_NO_REWRITE
export DSTDB_JDBC_REWRITE

set_jdbc_vars() {

local ARCION_HOME=${ARCION_HOME:-/arcion}
local SRCDB_USER_CHANGE="#_CHANGEME_#"
local DSTDB_USER_CHANGE="#_CHANGEME_#"
case "${SRCDB_GRP,,}" in
  ase)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="sybase"
    SRCDB_JDBC_DRIVER="com.sybase.jdbc4.jdbc.SybDriver"
    SRCDB_JDBC_URL="jdbc:sybase:Tds:${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:sybase:Tds:${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_NO_REWRITE=""
    SRCDB_JDBC_REWRITE=""      
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/jconn4*jar | paste -sd :)"
    ;; 
  db2)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="db2"
    SRCDB_JDBC_DRIVER="com.ibm.db2.jcc.DB2Driver"
    SRCDB_JDBC_URL="jdbc:db2://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:db2://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_NO_REWRITE=""
    SRCDB_JDBC_REWRITE=""
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/db2jcc-db2jcc4*jar | paste -sd :)"
    ;;
  snowflake)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="snowflake"
    SRCDB_JDBC_DRIVER="net.snowflake.client.jdbc.SnowflakeDriver"
    SRCDB_JDBC_URL="jdbc:snowflake://${SRCDB_HOST}:${SRCDB_PORT}/?schema=${SRCDB_SCHEMA}&warehouse=${SNOW_SRC_WAREHOUSE}&db=${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:snowflake://${SRCDB_HOST}:${SRCDB_PORT}/?schema=${SRCDB_SCHEMA}&amp;warehouse=${SNOW_SRC_WAREHOUSE}&amp;db=${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_NO_REWRITE=""
    SRCDB_JDBC_REWRITE=""
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/snowflake-jdbc*jar | paste -sd :)"
    if [[ -z $SRCDB_CLASSPATH ]]; then echo "${ARCION_HOME}/lib/snowflake-jdbc*jar not found" >&2; exit 1; fi 
    ;;
  oracle)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="oracle"
    SRCDB_JDBC_DRIVER="oracle.jdbc.OracleDriver"
    SRCDB_JDBC_URL="jdbc:oracle:thin:@//${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_SID}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:oracle:thin:@//${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_SID}"   
    SRCDB_JDBC_NO_REWRITE=""
    SRCDB_JDBC_REWRITE=""
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd :)"
    if [[ -z $SRCDB_CLASSPATH ]]; then echo "${ARCION_HOME}/lib/ojdbc8*jar not found" >&2; exit 1; fi 
    ;;
  informix)
    # JDBC settings 
    # https://www.ibm.com/docs/en/informix-servers/12.10?topic=database-informix-environment-variables-informix-jdbc-driver
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="informix"
    SRCDB_JDBC_DRIVER="com.informix.jdbc.IfxDriver"
    SRCDB_JDBC_URL="jdbc:informix-sqli://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:informix-sqli://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}:IFX_USEPUT=1;"   
    SRCDB_JDBC_NO_REWRITE="s/IFX_USEPUT=1/IFX_USEPUT=0/g"
    SRCDB_JDBC_REWRITE="s/IFX_USEPUT=0/IFX_USEPUT=1/g"
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/jdbc*jar ${ARCION_HOME}/lib/bson*jar | paste -sd :)"
    ;;
  mysql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mysql"
    SRCDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    SRCDB_JDBC_URL="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    SRCDB_JDBC_URL_BENCHBASE="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}?permitMysqlScheme&amp;restrictedAuth=mysql_native_password&amp;rewriteBatchedStatements=true"
    SRCDB_JDBC_NO_REWRITE="s/rewriteBatchedStatements=true/rewriteBatchedStatements=false/g"
    SRCDB_JDBC_REWRITE="s/rewriteBatchedStatements=false/rewriteBatchedStatements=true/g"    
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/maria*jar | paste -sd :)"
    ;;
  postgresql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="pgsql"
    SRCDB_JDBC_DRIVER="org.postgresql.Driver"
    SRCDB_JDBC_URL="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}?autoReconnect=true&sslmode=disable&ssl=false"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}?autoReconnect=true&amp;sslmode=disable&amp;ssl=false&amp;reWriteBatchedInserts=true"   
    SRCDB_JDBC_NO_REWRITE="s/reWriteBatchedInserts=true/reWriteBatchedInserts=false/g"
    SRCDB_JDBC_REWRITE="s/reWriteBatchedInserts=false/reWriteBatchedInserts=true/g"   
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/post*jar | paste -sd :)"
    ;;
  mongodb)
    SRCDB_YCSB_DRIVER="mongodb"
    SRCDB_JSQSH_DRIVER=""
    SRCDB_ROOT_URL="mongodb://${SRCDB_ROOT}:${SRCDB_PW}@${SRCDB_HOST}:${SRCDB_PORT}/"   
    SRCDB_JDBC_URL="mongodb://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_USER_CHANGE}?w=0"
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/mongodb*jar | paste -sd :)"
    ;;      
  sqlserver)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mssql2k5"
    SRCDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    # NOTE: YCSB bug https://github.com/brianfrankcooper/YCSB/issues/1458
    # cannot use ;databaseName=${DSTDB_ARC_USER}
    SRCDB_JDBC_URL="jdbc:sqlserver://${SRCDB_HOST}:${SRCDB_PORT}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:sqlserver://${SRCDB_HOST}:${SRCDB_PORT};database=${SRCDB_USER_CHANGE};encrypt=false;useBulkCopyForBatchInsert=true"   
    SRCDB_JDBC_NO_REWRITE="s/useBulkCopyForBatchInsert=true/useBulkCopyForBatchInsert=false/g"
    SRCDB_JDBC_REWRITE="s/useBulkCopyForBatchInsert=false/useBulkCopyForBatchInsert=true/g"      
    SRCDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/mssql*jar | paste -sd :)"
    ;;         
  *)
    echo "ini_jdbc.sh: SRCDB_GRP: ${SRCDB_GRP} need to code support" >&2
    ;;
esac

case "${DSTDB_GRP,,}" in
  ase)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="sybase"
    DSTDB_JDBC_DRIVER="com.sybase.jdbc4.jdbc.SybDriver"
    DSTDB_JDBC_URL="jdbc:sybase:Tds:${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:sybase:Tds:${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}"   
    DSTDB_JDBC_NO_REWRITE=""
    DSTDB_JDBC_REWRITE=""      
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/jconn4*jar | paste -sd :)"
    ;;
  db2)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="db2"
    DSTDB_JDBC_DRIVER="com.ibm.db2.jcc.DB2Driver"
    DSTDB_JDBC_URL="jdbc:db2://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:db2://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}"   
    DSTDB_JDBC_NO_REWRITE=""
    DSTDB_JDBC_REWRITE=""
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/db2jcc-db2jcc4*jar | paste -sd :)"
    ;;
  bigquery)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="bigquery"
    DSTDB_JDBC_DRIVER="com.simba.googlebigquery.jdbc.Driver"
    DSTDB_JDBC_URL=""   
    DSTDB_JDBC_URL_BENCHBASE=""   
    DSTDB_JDBC_NO_REWRITE=""
    DSTDB_JDBC_REWRITE=""
    DSTDB_CLASSPATH="$( find ${ARCION_HOME}/lib -name "GoogleBigQueryJDBC42*jar" | paste -sd :)"
    if [[ -z $SRCDB_CLASSPATH ]]; then echo "${ARCION_HOME}/lib/GoogleBigQueryJDBC42 not found" >&2; exit 1; fi 
    ;;
  snowflake)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="snowflake"
    DSTDB_JDBC_DRIVER="net.snowflake.client.jdbc.SnowflakeDriver"
    DSTDB_JDBC_URL="jdbc:snowflake://${DSTDB_HOST}:${DSTDB_PORT}/?db=${DSTDB_USER_CHANGE}&warehouse=${SNOW_DST_WAREHOUSE}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:snowflake://${DSTDB_HOST}:${DSTDB_PORT}/?db=${DSTDB_USER_CHANGE}&amp;schema=${DSTDB_SCHEMA}&amp;warehouse=${SNOW_DST_WAREHOUSE}"   
    DSTDB_JDBC_NO_REWRITE=""
    DSTDB_JDBC_REWRITE=""
    DSTDB_CLASSPATH="$( find ${ARCION_HOME}/lib -name "snowflake-jdbc*jar" | paste -sd :)"
    if [[ -z $SRCDB_CLASSPATH ]]; then echo "${ARCION_HOME}/lib/snowflake-jdbc*jar not found" >&2; exit 1; fi 
    ;;
  oracle)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="oracle"
    DSTDB_JDBC_DRIVER="oracle.jdbc.OracleDriver"
    DSTDB_JDBC_URL="jdbc:oracle:thin:@//${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_SID}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:oracle:thin:@//${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_SID}"   
    DSTDB_JDBC_NO_REWRITE=""
    DSTDB_JDBC_REWRITE=""
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd :)"
    if [[ -z $SRCDB_CLASSPATH ]]; then echo "${ARCION_HOME}/lib/ojdbc8*jar not found" >&2; exit 1; fi 

    ;;
  informix)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="informix"
    DSTDB_JDBC_DRIVER="com.informix.jdbc.IfxDriver"
    DSTDB_JDBC_URL="jdbc:informix-sqli://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:informix-sqli://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}:IFX_USEPUT=1;"   
    DSTDB_JDBC_NO_REWRITE="s/IFX_USEPUT=1/IFX_USEPUT=0/g"
    DSTDB_JDBC_REWRITE="s/IFX_USEPUT=0/IFX_USEPUT=1/g"
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/jdbc*jar ${ARCION_HOME}/lib/bson*jar | paste -sd :)"
    ;;
  mysql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mysql"
    DSTDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    DSTDB_JDBC_URL="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    DSTDB_JDBC_URL_BENCHBASE="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}?permitMysqlScheme&amp;restrictedAuth=mysql_native_password&amp;rewriteBatchedStatements=true"
    DSTDB_JDBC_NO_REWRITE="s/rewriteBatchedStatements=true/rewriteBatchedStatements=false/g"
    DSTDB_JDBC_REWRITE="s/rewriteBatchedStatements=false/rewriteBatchedStatements=true/g" 
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/maria*jar | paste -sd :)"
    ;;
  postgresql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="pgsql"
    DSTDB_JDBC_DRIVER="org.postgresql.Driver"
    DSTDB_JDBC_URL="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}?autoReconnect=true&sslmode=disable&ssl=false"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}?autoReconnect=true&amp;sslmode=disable&amp;ssl=false&amp;reWriteBatchedInserts=true"   
    DSTDB_JDBC_NO_REWRITE="s/reWriteBatchedInserts=true/reWriteBatchedInserts=false/g"
    DSTDB_JDBC_REWRITE="s/reWriteBatchedInserts=false/reWriteBatchedInserts=true/g" 
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/post*jar | paste -sd :)"
    ;; 
  mongodb)
    DSTDB_YCSB_DRIVER="mongodb"
    DSTDB_JSQSH_DRIVER=""
    DSTDB_ROOT_URL="mongodb://${DSTDB_ROOT}:${DSTDB_PW}@${DSTDB_HOST}:${DSTDB_PORT}/"
    DSTDB_JDBC_URL="mongodb://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_USER_CHANGE}?w=0"
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/mongodb*jar | paste -sd :)"
    ;;     
  sqlserver)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mssql2k5"
    DSTDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    # NOTE: YCSB bug https://github.com/brianfrankcooper/YCSB/issues/1458
    # cannot use ;databaseName=${DSTDB_ARC_USER}
    DSTDB_JDBC_URL="jdbc:sqlserver://${DSTDB_HOST}:${DSTDB_PORT};encrypt=false"
    DSTDB_JDBC_URL_BENCHBASE="jdbc:sqlserver://${DSTDB_HOST}:${DSTDB_PORT};;database=${DSTDB_USER_CHANGE};encrypt=false;useBulkCopyForBatchInsert=true"
    DSTDB_JDBC_NO_REWRITE="s/useBulkCopyForBatchInsert=true/useBulkCopyForBatchInsert=false/g"
    DSTDB_JDBC_REWRITE="s/useBulkCopyForBatchInsert=false/useBulkCopyForBatchInsert=true/g"  
    DSTDB_CLASSPATH="$( ls ${ARCION_HOME}/lib/mssql*jar | paste -sd :)"
    ;;     
  *)
    echo "ini_jdbc.sh: DSTDB_GRP: ${DSTDB_GRP} need to code support" >&2
    ;;
esac
}