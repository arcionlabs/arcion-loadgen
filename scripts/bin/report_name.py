#!/usr/bin/env python3

import click
from enum import Enum, unique, Flag
import fileinput
import numpy as np
import re
import shlex
import sys

@click.command(context_settings=dict(ignore_unknown_options=True))
@click.option("--max-errors", default=3, help="Stop after these many errors (default: 3)")
@click.option("--max-resumes", default=3, help="Stop after these many resumes (default: 3)")
def main(max_errors,max_resumes):
    """Move file SRC to DST."""
    print(f"max_errors={max_errors} max_resumes={max_resumes}")

if __name__ == "__main__":
    main()

snap1=re.compile(r"^Elapsed time: (\S+)\s+ETA: (\S+)\s+Peak Rate: (\S+)\s*$")
snap2=re.compile(r"^Average Rate: (\S+)\s+Current Rate: (\S+)\s+Used Memory\(%\): (\S+)\s*$")
snap3=re.compile(r"^Used Memory(%): (\S+)\s+.*$")

real1=re.compile(r"^Elapsed time: (\S+)\s+Initial avg rate: (\S+)\s+Initial load time: (\S+)\s*$")
real2=re.compile(r"^Peak Rate: (\S+)\s+Average Rate: (\S+)\s+Current Rate: (\S+)\s*$")
real3=re.compile(r"^Total Lag(ms): (\S+)\s+Replicate Lag\(ms\): (\S+)\s+Used Memory\(%\): (\S+)\s*$") 
real4=re.compile(r"^Replay Consistency: (\S+)\s+.*$")

resuming_replicant=re.compile(r"^Resuming replicant")
replicant_exited=re.compile(r"^replicant exited with error code: (\S)+")
real_col_names=re.compile(r"^Table name\s+Inserted")
snap_col_names=re.compile(r"Table name.*Rows")
empty_line=re.compile(r"^$")

DictArray=dict[list]

class ReplMode(Enum):
    UNKNOWN = 0
    SNAPSHOT = 1
    REALTIME = 2
    DELTA = 3

current_repl_mode:ReplMode = ReplMode.UNKNOWN

log_resume_cnt=0
log_error_cnt=0
log_blank_snap_count=0
log_blank_real_count=0

error_codes_seen=[]

flag_snapshot=0
flag_realtime=0

col_names=[]
table_stats={}
table_stats_sum=[]

last_table_snap_sum=[]
last_table_real_sum=[]

# column name and order out output
log_stats={
    'errors':0,             # number of replicant exited with error code: ?
    'error_codes':[],       # sequence of error
    'resumes':0,            # number of Resuming replicant........
    'flip_flops':0,         # snapshot to realtime back to snapshot
    'snapshot_blanks':0,    # number of snapshot summary that had blank tables
    'realtime_blanks':0,    # number of snapshot summary that had blank tables
    'snapshot_tables':0,    # number of tables in snapshot
    'realtime_tables':0,    # number of tables in realtime
    'snapshotted':0,        # total rows snapshotted
    'Inserted':0,           # total rows inserted
    'Deleted':0,            # total rows deleted
    'Updated':0,            # total rows updated
    'Replaced':0,           # total rows replaced
    'DDL':0,                # total ddl operations
    'BufferedOpers';0,      #
    }

#  column and the order of output
col_names_real={
    'Inserted':0,      
    'Deleted':1,       
    'Updated':3,       
    'Replaced':4,  
    'DDL':5, 
    'BufferedOpers':6 
    }

#  state
state={}

# AWK like stats 
FNR=0    # number of records relative to replication stat 
NF=0     # number of fields

def setReplMode(repl_mode:ReplMode):
    FNR=0
    if (current_repl_mode == repl_mode):
        return
    if (current_repl_mode == ReplMode.UNKNOWN):
        current_repl_mode = repl_mode
        return
    if (current_repl_mode == ReplMode.SNAPSHOT and repl_mode == ReplMode.REALTIME):
        current_repl_mode = repl_mode
        return
    current_repl_mode = repl_mode
    log_stats.flip_flops+=1
    
for line in fileinput.input():
    found_resume=resuming_replicant.match(line)
    if found_resume:
        log_stats['resumes']+=1
        continue

    found_error=replicant_exited.match(line)
    if found_error:
        log_stats['resumes']+=1
        log_stats['error_codes']+=found_error.groups()
        continue

    found_realtime=real_col_names.match(line)
    if found_realtime:
        setReplMode(ReplMode.REALTIME)
        col_names=shlex.split(line)
        table_real_sum=np.full(len(col_names)-2-2,0) # -2 for table name , -2 for rate and lag
        continue

    found_snapshot=snap_col_names.match(line)
    if found_snapshot:
        current_repl_mode=ReplMode.SNAPSHOT
        col_names=shlex.split(line)
        table_snap_sum=np.full(1,0)
        continue

    # start processing tabular data
    if current_repl_mode==ReplMode.REALTIME:
        found_end_screen=empty_line.match(line)
        if found_end_screen:
            #print(NR,table_real_sum)
            if (FNR==0): log_stats['realtime_blanks']+=1
            else:
                last_table_real_sum=table_real_sum
                last_real_tables=NR
            table_stats={}
            flag_realtime=0
            continue
        try:
            cols=shlex.split(line)
        except:
            cols=line.split()

        if len(cols)<=1:
            continue
        NR+=1
        table_stats[cols[0]]=cols
        #print(f"real stat={table_real_sum}")
        #print(f"real cols={cols}")
        #  skip 0:name, -2:rate, lag
        table_real_sum = np.add(table_real_sum, np.array(cols[1:-2], dtype=int)) 
        
    if flag_snapshot:
        found_end_screen=empty_line.match(line)
        if found_end_screen:
            #print(NR,table_snap_sum)
            if (NR==0): log_blank_snap_count+=1
            else:
                last_table_snap_sum=table_snap_sum
                last_snap_tables=NR
            flag_snapshot=0
            table_stats={}
            continue
        try:
            cols=shlex.split(line)
        except:
            cols=line.split()
        if len(cols)<=1:
            continue
        NR+=1
        table_stats[cols[0]]=cols
        #print(f"snap stat={table_snap_sum}")
        #print(f"snap cols={cols}")
        table_snap_sum = np.add(table_snap_sum, np.array(cols[1:2], dtype=int))
        #print(f"snap stat={table_snap_sum}")

print(f"resume={log_resume_cnt} error={log_error_cnt} error_codes={error_codes_seen} blank_real={log_blank_real_count} blank_snap={log_blank_snap_count} snap_tally={last_table_snap_sum} real_tally={last_table_real_sum}")

