-- Enable logs on database
-- https://docs.arcion.io/docs/source-setup/oracle/setup-guide/oracle-traditional-database/#enable-logs
-- not having this will result in
-- CDC not enabled
ALTER DATABASE FORCE LOGGING;

ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- native log reader
GRANT SELECT ON gv_\$instance TO ${SRCDB_ARC_USER};
GRANT SELECT ON v_\$log TO ${SRCDB_ARC_USER};
GRANT SELECT ON v_\$logfile TO ${SRCDB_ARC_USER};
GRANT SELECT ON v_\$archived_log to ${SRCDB_ARC_USER};
GRANT SELECT ON dba_objects TO ${SRCDB_ARC_USER};
GRANT SELECT ON v_\$transportable_platform TO ${SRCDB_ARC_USER};

-- missing in the docs
GRANT SELECT ON V_$DATABSSE TO ${SRCDB_ARC_USER};

-- GIANT HACK as there are others missing as well
 grant dba to  ${SRCDB_ARC_USER};