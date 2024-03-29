grant dataaccess on database to user ${DSTDB_ARC_USER};
grant load on database to user ${DSTDB_ARC_USER};

-- required to get past schema creation
grant dbadm on database to user ${DSTDB_ARC_USER};

-- The user should have read access to following system tables and views:

GRANT SELECT ON TABLE SYSIBM.SYSTABLES to ${DSTDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SQLTABLETYPES to ${DSTDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SYSCOLUMNS to ${DSTDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SYSTABCONST to ${DSTDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SQLCOLUMNS to ${DSTDB_ARC_USER};
GRANT SELECT ON TABLE SYSCAT.COLUMNS  to ${DSTDB_ARC_USER}; 

-- The user should have execute permissions on the following system procedures:

GRANT EXECUTE ON PROCEDURE SYSIBM.SQLTABLES to ${DSTDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLCOLUMNS to ${DSTDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLPRIMARYKEYS to ${DSTDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLSTATISTICS to ${DSTDB_ARC_USER};