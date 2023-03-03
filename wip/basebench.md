
```bash
./mvnw clean 
./mvnw  package -P postgres
./mvnw  package -P mysql
./mvnw  package -P mariadb
./mvnw  package -P sqlserver

# https://mvnrepository.com/artifact/com.ibm.informix/jdbc
./mvnw  package -P informix

# http://www.java2s.com/Open-Source/Maven_Repository/JDBC/jtds/jtds_1_3_1.htm
# https://apereo.atlassian.net/wiki/spaces/UPM40/pages/103728535/Sybase+SQL+Server
```