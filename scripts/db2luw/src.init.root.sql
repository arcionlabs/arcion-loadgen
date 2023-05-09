create user ${SRCDB_ARC_USER} with password '${SRCDB_ARC_PW}';
-- create database IF NOT EXISTS ${SRCDB_DB} with LOG;

database ${SRCDB_DB};
grant resource to ${SRCDB_ARC_USER};
grant connect to ${SRCDB_ARC_USER};

-- The user should have read access to following system tables and views:

 SYSIBM.SYSTABLES

SYSIBM.SQLTABLETYPES

SYSIBM.SYSCOLUMNS

SYSIBM.SYSTABCONST

SYSIBM.SQLCOLUMNS

SYSCAT.COLUMNS -- (required for fetch-schemas mode).

-- The user should have execute permissions on the following system procedures:

a. SYSIBM.SQLTABLES

b. SYSIBM.SQLCOLUMNS

c. SYSIBM.SQLPRIMARYKEYS

d. SYSIBM.SQLSTATISTICS