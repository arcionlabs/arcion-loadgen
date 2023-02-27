
NOTE: Does not run on Apple Silicon

```
docker run --platform linux/amd64 --name sqlserver -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```

```
docker run -d --name sqlserver --network arcnet \
--cap-add SYS_PTRACE \
-e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Passw0rd' \
-p 1433:1433 \
mcr.microsoft.com/azure-sql-edge
```