sp_addlogin arcdst, Passw0rd, master 
go
-- add user into the database for the login
use arcdst
go
sp_adduser arcdst
go
grant all to arcdst
go
sp_role 'grant', sa_role, arcdst
go
sp_role 'grant', replication_role, arcdst
go
sp_role 'grant', sybase_ts_role, arcdst
go
