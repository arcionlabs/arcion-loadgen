#!/usr/bin/env bash

# https://blog.min.io/command-line-access-to-google-cloud-storage/#:~:text=To%20use%20mc%20with%20google%20cloud%20storage%2C%20you,access%20key%20and%20secret%20key.%20Note%20them%20down.

# create arcdst user alias
mc alias set wasabi ${WASABI_DST_ENDPOINT} ${WASABI_DST_ID} ${WASABI_DST_SECRET}
# create arcdst bucket
#mc mb  --with-lock ${DSTDB_ARC_USER}/${DSTDB_DB}
# list buckets 
mc ls -r wasabi/${DSTDB_DB}
# Creating an object whose name ends with a "/" will create a folder. It is an empty object that simulates a directory. link

