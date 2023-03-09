
NOTE: Does not run on Apple Silicon

For amd64
```
docker run -d --name sqlserver  --network arcnet \
    -e "ACCEPT_EULA=Y" \
    -e "MSSQL_SA_PASSWORD=Passw0rd" \
    -p 1433:1433 \
    -d mcr.microsoft.com/mssql/server:2022-latest
```

for arm64
```
docker run -d --name sqlserver --network arcnet \
--cap-add SYS_PTRACE \
-e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Passw0rd' \
-p 1433:1433 \
mcr.microsoft.com/azure-sql-edge
```


