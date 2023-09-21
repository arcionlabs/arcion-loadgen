#!/usr/bin/env bash

test1() {

dialog --form "arcion command line" 0 0 10 \
label  1 0 item  1 7 10 10 \
label2 2 0 item2 2 7 10 10 \
label3 3 0 item3 3 7 10 10 
}

dialog --menu "select source" 0 0 10 \
mysql mysql \
pg pg 

