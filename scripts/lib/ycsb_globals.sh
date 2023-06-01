#!/usr/env/bin bash

[ -z "${YCSB_JDBC}" ] && YCSB_JDBC=/opt/ycsb/ycsb-jdbc-binding-0.18.0-SNAPSHOT

# defaults for the command line
export default_ycsb_rate=1
export default_ycsb_threads=1
export default_ycsb_timer=600
export default_ycsb_size_factor=1
export default_ycsb_batchsize=1024        
export default_ycsb_table="THEUSERTABLE"  # YCSB default=usertable
export default_ycsb_fieldcount=10         # YCSB default
export default_ycsb_fieldlength=100       # YCSB default

# set defaults
[ -z "${ycsb_rate}" ]        && export ycsb_rate=${default_ycsb_rate}
[ -z "${ycsb_threads}" ]     && export ycsb_threads=${default_ycsb_threads}
[ -z "${ycsb_timer}" ]       && export ycsb_timer=${default_ycsb_timer}
[ -z "${ycsb_size_factor}" ] && export ycsb_size_factor=${default_ycsb_size_factor}
[ -z "${ycsb_batchsize}" ]   && export ycsb_batchsize=${default_ycsb_batchsize}

# constants
export const_ycsb_insertstart=0
export const_ycsb_recordcount=100000
export const_ycsb_operationcount=1000000000
export const_ycsb_zeropadding=11
export const_ycsb_ycsbkeyprefix=0
