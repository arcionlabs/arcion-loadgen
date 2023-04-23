
- default tablespace where user would use

```
select *
from database_properties
where property_name like 'DEFAULT%TABLESPACE';

+------------------------------+----------------+--------------------------------------+
| PROPERTY_NAME                | PROPERTY_VALUE | DESCRIPTION                          |
+------------------------------+----------------+--------------------------------------+
| DEFAULT_PERMANENT_TABLESPACE | USERS          | Name of default permanent tablespace |
| DEFAULT_TEMP_TABLESPACE      | TEMP           | Name of default temporary tablespace |
+------------------------------+----------------+--------------------------------------+
```

- archivelog is enabled

```bash
select log_mode from v$database;
+------------+
| LOG_MODE   |
+------------+
| ARCHIVELOG |
+------------+
```