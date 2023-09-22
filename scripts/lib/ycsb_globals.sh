#!/usr/env/bin bash

[ -z "${YCSB_JDBC}" ] && YCSB_JDBC=/opt/ycsb/ycsb-jdbc-binding-0.18.0-SNAPSHOT

# defaults for the command line
export default_ycsb_modules_csv="ycsbsparse"    #ycsbsparse,ycsbdense
export default_ycsb_loc="SRC"
export default_ycsb_rate=1
export default_ycsb_threads=1
export default_ycsb_timer=600
export default_ycsb_size_factor=1
export default_ycsb_batchsize=1024        
export default_ycsb_fieldcount=10         # YCSB default
export default_ycsb_fieldlength=100       # YCSB default

# workaround to export the dict
# where this is required, do the following
#   eval ${default_ycsb_table_dict_export}
#   declare -p default_ycsb_table_dict 
declare -A default_ycsb_table_dict=(
    ["ycsbsparse"]="YCSBSPARSE" 
    ["ycsbdense"]="YCSBDENSE" 
    )
export default_ycsb_table_dict_export="$(declare -p default_ycsb_table_dict)"    

declare -A default_ycsb_fieldcount_dict=(
    ["ycsbsparse"]=0 
    ["ycsbdense"]=${default_ycsb_fieldcount} 
    )
export default_ycsb_fiedlcount_dict_export="$(declare -p default_ycsb_fieldcount_dict)" 

# set defaults
[ -z "${ycsb_modules_csv}" ] && export ycsb_modules_csv=${default_ycsb_modules_csv}
[ -z "${ycsb_rate}" ]        && export ycsb_rate=${default_ycsb_rate}
[ -z "${ycsb_threads}" ]     && export ycsb_threads=${default_ycsb_threads}
[ -z "${ycsb_timer}" ]       && export ycsb_timer=${default_ycsb_timer}
[ -z "${ycsb_size_factor}" ] && export ycsb_size_factor=${default_ycsb_size_factor}
[ -z "${ycsb_batchsize}" ]   && export ycsb_batchsize=${default_ycsb_batchsize}

# constants
export const_ycsb_insertstart=0
export const_ycsb_recordcount=1000000
export const_ycsb_operationcount=1000000000
export const_ycsb_zeropadding=11
export const_ycsb_ycsbkeyprefix=0
