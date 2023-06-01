CREATE LOGIN ${SRCDB_ARC_USER} WITH PASSWORD '${SRCDB_ARC_PW}';

disk resize name='master', size='30000M';
-- 20GB takes about 1 min
create database arcsrc on master = '20000M'

create database ${SRCDB_DB};

use ${SRCDB_ARC_USER};

-- https://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc01672.1572/html/sec_admin/BCFIJEEG.htm
sp_adduser arcsrc;


ALTER ROLE db_owner ADD MEMBER ${SRCDB_ARC_USER};
ALTER ROLE db_ddladmin ADD MEMBER ${SRCDB_ARC_USER};
alter user ${SRCDB_ARC_USER} with default_schema=dbo;
ALTER LOGIN ${SRCDB_ARC_USER} WITH DEFAULT_DATABASE=[${SRCDB_DB}];

