#!/usr/bin/env bash

# dump and diff the entire data
# for cases when the source is different, just select columns from the source

while [ 1 ]; do
    mysql -hsinglestore -uarcsrc -ppassword -Darcsrc -B -e "select ts,* from sbtest1 order by ts,id" > source.sbtest1.tsv

    mysql -hsinglestore -uarcsrc -ppassword -Darcsrc -B -e "select ts,* from usertable order by ts,ycsb_key" > source.usertable.tsv

    mysql -hsinglestore-2 -uarcsrc -ppassword -Darcsrc -B -e "select ts,* from sbtest1 order by ts,id" > dest.sbtest1.tsv

    mysql -hsinglestore-2 -uarcsrc -ppassword -Darcsrc -B -e "select ts,* from usertable order by ts,ycsb_key" > dest.usertable.tsv

    diff source.sbtest1.tsv dest.sbtest1.tsv | cut -f1,2
    diff source.usertable.tsv dest.usertable.tsv | cut -f1,2

    sleep 1
done