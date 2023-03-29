#!/usr/bin/env bash

# 
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

case "${SRCDB_GRP,,}" in
  # JDBC settings 
  # https://www.ibm.com/docs/en/informix-servers/12.10?topic=database-informix-environment-variables-informix-jdbc-driver
  informix)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="informix"
    SRCDB_JDBC_DRIVER="com.informix.jdbc.IfxDriver"
    SRCDB_JDBC_URL="jdbc:informix-sqli://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:informix-sqli://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}:IFX_USEPUT=1;"   
    SRCDB_JDBC_URL_IDPW="jdbc:informix-sqli:://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}"
    SRCDB_JDBC_NO_REWRITE="s/IFX_USEPUT=1/IFX_USEPUT=0/g"
    SRCDB_JDBC_REWRITE="s/IFX_USEPUT=0/IFX_USEPUT=1/g"
    ;;
  mysql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mysql"
    SRCDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    SRCDB_JDBC_URL="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    SRCDB_JDBC_URL_BENCHBASE="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme&amp;restrictedAuth=mysql_native_password&amp;rewriteBatchedStatements=true"
    SRCDB_JDBC_URL_IDPW="jdbc:mysql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    SRCDB_JDBC_NO_REWRITE="s/rewriteBatchedStatements=true/rewriteBatchedStatements=false/g"
    SRCDB_JDBC_REWRITE="s/rewriteBatchedStatements=false/rewriteBatchedStatements=true/g"    
    ;;
  postgresql)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="pgsql"
    SRCDB_JDBC_DRIVER="org.postgresql.Driver"
    SRCDB_JDBC_URL="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&amp;sslmode=disable&amp;ssl=false&amp;reWriteBatchedInserts=true"   
    SRCDB_JDBC_URL_IDPW="postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"
    SRCDB_JDBC_NO_REWRITE="s/reWriteBatchedInserts=true/reWriteBatchedInserts=false/g"
    SRCDB_JDBC_REWRITE="s/reWriteBatchedInserts=false/reWriteBatchedInserts=true/g"   
    ;;
  mongodb)
    SRCDB_YCSB_DRIVER="mongodb"
    SRCDB_JSQSH_DRIVER=""
    SRCDB_ROOT_URL="mongodb://${SRCDB_ROOT}:${SRCDB_PW}@${SRCDB_HOST}:${SRCDB_PORT}/"   
    SRCDB_JDBC_URL="mongodb://${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?w=0"
    SRCDB_JDBC_URL_IDPW="mongodb://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}?w=0"
    ;;
  sqlserver)
    SRCDB_YCSB_DRIVER="jdbc"
    SRCDB_JSQSH_DRIVER="mssql2k5"
    SRCDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    # NOTE: YCSB bug https://github.com/brianfrankcooper/YCSB/issues/1458
    # cannot use ;databaseName=${DSTDB_ARC_USER}
    SRCDB_JDBC_URL="jdbc:sqlserver://${SRCDB_HOST}:${SRCDB_PORT}"   
    SRCDB_JDBC_URL_BENCHBASE="jdbc:sqlserver://${SRCDB_HOST}:${SRCDB_PORT};encrypt=false;useBulkCopyForBatchInsert=true"   
    SRCDB_JDBC_URL_IDPW="sqlserver://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}"
    SRCDB_JDBC_NO_REWRITE="s/useBulkCopyForBatchInsert=true/useBulkCopyForBatchInsert=false/g"
    SRCDB_JDBC_REWRITE="s/useBulkCopyForBatchInsert=false/useBulkCopyForBatchInsert=true/g"      
    ;;         
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support" >&2
    ;;
esac

case "${DSTDB_GRP,,}" in
  informix)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="informix"
    DSTDB_JDBC_DRIVER="com.informix.jdbc.IfxDriver"
    DSTDB_JDBC_URL="jdbc:informix-sqli://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:informix-sqli://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}:IFX_USEPUT=1;"   
    DSTDB_JDBC_URL_IDPW="jdbc:informix-sqli:://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}"
    DSTDB_JDBC_NO_REWRITE="s/IFX_USEPUT=1/IFX_USEPUT=0/g"
    DSTDB_JDBC_REWRITE="s/IFX_USEPUT=0/IFX_USEPUT=1/g"
    ;;
  mysql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mysql"
    DSTDB_JDBC_DRIVER="org.mariadb.jdbc.Driver"
    DSTDB_JDBC_URL="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    DSTDB_JDBC_URL_BENCHBASE="jdbc:mysql://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme&amp;restrictedAuth=mysql_native_password&amp;rewriteBatchedStatements=true"
    DSTDB_JDBC_URL_IDPW="jdbc:mysql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
    DSTDB_JDBC_NO_REWRITE="s/rewriteBatchedStatements=true/rewriteBatchedStatements=false/g"
    DSTDB_JDBC_REWRITE="s/rewriteBatchedStatements=false/rewriteBatchedStatements=true/g" 
    ;;
  postgresql)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="pgsql"
    DSTDB_JDBC_DRIVER="org.postgresql.Driver"
    DSTDB_JDBC_URL="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${ARCDST_USER}?autoReconnect=true&sslmode=disable&ssl=false"   
    DSTDB_JDBC_URL_BENCHBASE="jdbc:postgresql://${DSTDB_HOST}:${DSTDB_PORT}/${ARCDST_USER}?autoReconnect=true&amp;sslmode=disable&amp;ssl=false&amp;reWriteBatchedInserts=true"   
    DSTDB_JDBC_URL_IDPW="postgresql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?autoReconnect=true&sslmode=disable&ssl=false"
    DSTDB_JDBC_NO_REWRITE="s/reWriteBatchedInserts=true/reWriteBatchedInserts=false/g"
    DSTDB_JDBC_REWRITE="s/reWriteBatchedInserts=false/reWriteBatchedInserts=true/g" 
    ;; 
  mongodb)
    DSTDB_YCSB_DRIVER="mongodb"
    DSTDB_JSQSH_DRIVER=""
    DSTDB_ROOT_URL="mongodb://${DSTDB_ROOT}:${DSTDB_PW}@${DSTDB_HOST}:${DSTDB_PORT}/"
    DSTDB_JDBC_URL="mongodb://${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?w=0"
    DSTDB_JDBC_URL_IDPW="mongodb://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}?w=0"
    ;;     
  sqlserver)
    DSTDB_YCSB_DRIVER="jdbc"
    DSTDB_JSQSH_DRIVER="mssql2k5"
    DSTDB_JDBC_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    # NOTE: YCSB bug https://github.com/brianfrankcooper/YCSB/issues/1458
    # cannot use ;databaseName=${DSTDB_ARC_USER}
    DSTDB_JDBC_URL="jdbc:sqlserver://${DSTDB_HOST}:${DSTDB_PORT};encrypt=false"
    DSTDB_JDBC_URL_BENCHBASE="jdbc:sqlserver://${DSTDB_HOST}:${DSTDB_PORT};encrypt=false;useBulkCopyForBatchInsert=true"
    DSTDB_JDBC_URL_IDPW="sqlserver://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}"
    DSTDB_JDBC_NO_REWRITE="s/useBulkCopyForBatchInsert=true/useBulkCopyForBatchInsert=false/g"
    DSTDB_JDBC_REWRITE="s/useBulkCopyForBatchInsert=false/useBulkCopyForBatchInsert=true/g"  
    ;;     
  *)
    echo "$0: DSTDB_GRP: ${DSTDB_GRP} need to code support" >&2
    ;;
esac
}