#!/usr/bin/env bash

export REALTIME_TOTAL_ROWS_NULL="0 0 0 0 0"
export DELTA_TOTAL_ROWS_NULL="0 0 0"
export SNAPSHOT_TOTAL_ROWS_NULL="0 0"

arcionlog_snap_parser() {
    # snapshot summary that has the following
    # table_cnt " " total_row_cnt
    export snapshot_total_rows=${SNAPSHOT_TOTAL_ROWS_NULL}

    if [[ ! -f "${LOG_DIR}/snapshot_summary.txt" ]]; then return 0; fi
    
    snapshot_total_rows=$(cat ${LOG_DIR}/snapshot_summary.txt | \
        awk '
        BEGIN {flag=0; table_cnt=0; row_cnt=0; flag=0}
        /^_+$/ {flag=1; next;}
        flag==1 && NF==0 {exit}
        flag==1 {table_cnt++; row_cnt=row_cnt+$NF}
        END {print table_cnt " " row_cnt}
        ' )
}

arcionlog_real_delta_parser() {

    export realtime_total_rows=${REALTIME_TOTAL_ROWS_NULL}
    export delta_total_rows=${DELTA_TOTAL_ROWS_NULL}

    # real-time summary 
    if [[ "${run_repl_mode}" = "snapshot" ]]; then return 0; fi
    if [[ ! ${CFG_DIR}/arcion.log ]]; then return 0; fi
   
    tac ${CFG_DIR}/arcion.log | \
        awk '
        {print $0}
        $1=="Table" && $2=="name" {exit}
        ' > /tmp/real_time.log.$$

   # table_cnt " " inserted " " deleted " " updated " " replaced
   realtime_total_rows=$( tac /tmp/real_time.log.$$ | \
      awk '
         BEGIN {inserted=0; deleted=0; updated=0; replaced=0; table_cnt=0; num_of_columns=0; tablename=0}
         $1=="Table" && $2=="name" {tablename=1; num_of_columns=NF-1; next}
         tablename==1 && NF==num_of_columns {inserted+=$2; deleted+=$3; updated+=$4; replaced+=$5; table_cnt++}
         END {print table_cnt " " inserted " " deleted " " updated " " replaced}
      ' )
   # applied incoming
   delta_total_rows=$( tac /tmp/real_time.log.$$ | \
      awk -F '[[:space:]/]+' '
         BEGIN {applied=0; incoming=0; table_cnt=0; replication_found=0}
         $1=="Table" && $2=="name" && $3=="Replication" {replication_found=1; next}
         replication_found==1 && NF>1 {table_cnt++; applied+=$(NF-3); incoming+=$(NF-2)}
         END {print table_cnt " " applied " " incoming}
      ' )
   # cleanup
   rm /tmp/real_time.log.$$
}
