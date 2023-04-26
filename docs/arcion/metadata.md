# Namespace mapping

a table can be referenced as catalog.schema.table. 
namespace convention for each database are below.

- catalog / database (all databases except Oracle)
- schema / owner (postgres, oracle, informix, sqlserver)

- sid oracle listener name for connection 
- server informix database server name

Database    | catalog   | schema    | sid   | server 
MySQL       | database  |           |       |
Postgres    | catalog   | schema    |       |
Oracle      |           | owner     | sid   |
SQL Server  | catalog   | schema    |       |
Informix    | database  | owner     |       | server
Sybase      |           |           |       |
MongoDB     |           |           |       |

# Connect string

scheme://username:password@hostname:port/[sid|database]

# Case sensitivity 

Arcion is case sensitive to work with all databases. 
Metadata references for owner, database, table and column names need to match the database specification. 

Database    |  
MySQL       | 
Postgres    | 
Oracle      | all caps       |
SQL Server  | case sensitive |
Informix    | 

