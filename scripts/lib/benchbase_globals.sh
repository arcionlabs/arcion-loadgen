#!/usr/bin/env bash

# defaults for the command line
export default_bb_rate=1
export default_bb_threads=1
export default_bb_timer=600
export default_bb_size_factor=1
export default_bb_batchsize=128
export default_bb_modules_csv="tpcc"

# set defaults
[ -z "${bb_rate}" ]        && export bb_rate=${default_bb_rate}
[ -z "${bb_threads}" ]     && export bb_threads=${default_bb_threads}
[ -z "${bb_timer}" ]       && export bb_timer=${default_bb_timer}
[ -z "${bb_size_factor}" ] && export bb_size_factor=${default_bb_size_factor}
[ -z "${bb_batchsize}" ]   && export bb_batchsize=${default_bb_batchsize}
[ -z "${bb_modules_csv}" ] && export bb_modules_csv=${default_bb_modules_csv}

# constants
export const_bb_modules_all_csv="resourcestresser,sibench,smallbank,tatp,tpcc,twitter,voter,ycsb"
