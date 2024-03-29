grant dataaccess on database to user ${SRCDB_ARC_USER};
grant load on database to user ${SRCDB_ARC_USER};

-- The user should have read access to following system tables and views:

GRANT SELECT ON TABLE SYSIBM.SYSTABLES to ${SRCDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SQLTABLETYPES to ${SRCDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SYSCOLUMNS to ${SRCDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SYSTABCONST to ${SRCDB_ARC_USER};
GRANT SELECT ON TABLE SYSIBM.SQLCOLUMNS to ${SRCDB_ARC_USER};
GRANT SELECT ON TABLE SYSCAT.COLUMNS  to ${SRCDB_ARC_USER}; 

-- The user should have execute permissions on the following system procedures:

GRANT EXECUTE ON PROCEDURE SYSIBM.SQLTABLES to ${SRCDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLCOLUMNS to ${SRCDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLPRIMARYKEYS to ${SRCDB_ARC_USER};
GRANT EXECUTE ON PROCEDURE SYSIBM.SQLSTATISTICS to ${SRCDB_ARC_USER};