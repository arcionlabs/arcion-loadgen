sp_addlogin arcdst, Passw0rd, master 
go
use arcdst
go
sp_adduser arcdst
go
-- probably below are not required for dst
grant all to arcdst
go
grant sa_role to arcdst
go
grant replication_role to arcdst
go
grant sybase_ts_role to arcdst
go
