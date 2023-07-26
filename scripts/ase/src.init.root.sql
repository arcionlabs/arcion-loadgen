-- disk resize name='master', size='30000M'

-- 20GB takes about 1 min
-- create database arcsrc on master = '20000M'

-- https:gra//infocenter-archive.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc36273.1502/html/sprocs/X25636.htm
-- https://infocenter-archive.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc36273.1502/html/sprocs/X25636.htm
sp_addlogin arcsrc, Passw0rd, master 
go
-- add user into the database for the login
use arcsrc
go
sp_adduser arcsrc
go
grant all to arcsrc
go
sp_role 'grant', sa_role, arcsrc
go
sp_role 'grant', replication_role, arcsrc
go
sp_role 'grant', sybase_ts_role, arcsrc
go

-- https://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc32300.1570/html/sqlug/X20276.htm
-- this would make the arcsrc instead of dbo
-- sp_tables @table_owner = "arcsrc"