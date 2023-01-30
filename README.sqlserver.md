
NOTE: Does not run on Apple Silicon

```
docker run --name sqlserver-db -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```