#!/usr/bin/env python3

import glob
import sys
import fire

from pathlib import Path
import jaydebeapi as jdbc
from urllib.parse import urlsplit

"""
https://www.mydatahack.com/how-to-bulk-load-data-with-jdbc-and-python/
"""

def jdbcConnect(
    jdbcname = "org.mariadb.jdbc.Driver", 
    url = "jdbc:mysql://mysql/arcsrc", 
    user = "arcsrc", 
    password = "Passw0rd", 
    props={},
    classpath = None):

    conn = jdbc.connect(
        jdbcname,
        url,
        {'user': user, 'password': password, **props},
        classpath,)
    print("connected")
    return conn
        
def main():
    """
    """
    conn=jdbcConnect()
    print("here")
    curs = conn.cursor()
    curs.execute("show tables")
    print(curs.fetchall())

    curs.execute('create table if not exists customer'
                 '(cust_id integer auto_increment,'
                 ' name varchar(50) not null,'
                 ' primary key (cust_id))'
                )
    curs.execute("insert into customer (name) values ('john')")
    curs.execute("select * from customer")
    print(curs.fetchall())
    curs.close()
    conn.close()

if __name__ == "__main__":
    fire.Fire(main)