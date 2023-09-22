#!/usr/bin/env python3

import re
import click
from datetime import datetime

begin_time=None
src_thread={}
dst_thread={}
meta_thread={}
oth_thread={}
logger_missing={}
job_name={}

# 2023-08-30 13:37:42.649 DEBUG [pool-20-thread-1] t.r.d.ExtractorTaskLogger: C##ARCSRC.OORDER : SRC-TASK : Fetched row count for job: 13628193-5437-460a-81fd-a9d7a23fbe15: 30000\n
colon5=re.compile('(?P<a_year>\d{2,4})-(?P<a_month>\d{2})-(?P<a_day>\d{2}) (?P<an_hour>\d{2}):(?P<a_minute>\d{2}):(?P<a_second>\d{2}[.\d]*) (?P<a_log_level>\w+) \[(?P<a_thread>\S+)\] (?P<a_logger>.+): (?P<a_table>.+): (?P<a_srcdst>.+): (?P<a_cmd>.+): (?P<a_job>.+): (?P<a_desc>.+$)')

# 2023-08-30 19:09:47.104 DEBUG [pool-17-thread-2] t.r.d.ExtractorTaskLogger: arcsrc.order_line : SRC-TASK : Executing sql on source : SELECT MIN(`ol_w_id`), MAX(`ol_w_id`) FROM  `arcsrc`.`order_line` 
colon4=re.compile('(?P<a_year>\d{2,4})-(?P<a_month>\d{2})-(?P<a_day>\d{2}) (?P<an_hour>\d{2}):(?P<a_minute>\d{2}):(?P<a_second>\d{2}[.\d]*) (?P<a_log_level>\w+) \[(?P<a_thread>\S+)\] (?P<a_logger>.+): (?P<a_table>.+): (?P<a_srcdst>.+): (?P<a_cmd>.+): (?P<a_desc>.+$)')

colon3 = re.compile('(?P<a_year>\d{2,4})-(?P<a_month>\d{2})-(?P<a_day>\d{2}) (?P<an_hour>\d{2}):(?P<a_minute>\d{2}):(?P<a_second>\d{2}[.\d]*) (?P<a_log_level>\w+) \[(?P<a_thread>\S+)\] (?P<a_logger>.+): (?P<a_srcdst>.+): (?P<a_table>.+): (?P<a_desc>.+$)')

logger_re = re.compile('(?P<a_year>\d{2,4})-(?P<a_month>\d{2})-(?P<a_day>\d{2}) (?P<an_hour>\d{2}):(?P<a_minute>\d{2}):(?P<a_second>\d{2}[.\d]*) (?P<a_log_level>\w+) \[(?P<a_thread>\S+)\] (?P<a_logger>[^:]+):(?P<a_desc>.+)$')

job_name = re.compile('^.+(?P<a_job>\s{8}-\s{4}-\s{4}-\s{4}-\s{12}).+$')

trdjoOracleDatabase_re3=re.compile('(?P<a_srcdst>[^:]+):(?P<a_cmd>[^:]+):(?P<a_desc>.+)$')
trdjoOracleDatabase_re2=re.compile('(?P<a_table>[^:]+):(?P<a_desc>.+)$')

def trMain(line:str):
    pass

def trcConfigLoaderUtils(line:str):
    pass

def trLivenessMonitor(line:str):

def trdExtractorTaskLogger(row):
    """
    # 2023-08-30 19:09:50.341 DEBUG [pool-18-thread-1] t.r.d.ExtractorTaskLogger: SRC-TASK : arcsrc.YCSBSPARSE: Published batch of 5000 rows
    # 2023-08-30 19:09:47.104 DEBUG [pool-17-thread-2] t.r.d.ExtractorTaskLogger: arcsrc.order_line : SRC-TASK : Executing sql on source : SELECT MIN(`ol_w_id`), MAX(`ol_w_id`) FROM  `arcsrc`.`order_line` 

    """
    if row['a_table'] == 'SRC-TASK':
        row['a_table'] = row['a_srcdst']           
        row['a_srcdst'] = 'SRC-TASK' 

def trdApplierTaskLogger(row):
    """2023-08-30 19:09:47.802 DEBUG [pool-19-thread-1] t.r.d.ApplierTaskLogger: arcdst.public.order_line : DST-TASK : COPY Done"""
    if row['a_table'] == 'DST-TASK':
        row['a_table'] = row['a_srcdst']           
        row['a_srcdst'] = 'DST-TASK'    

def trdjoOracleDatabase(row):
    """"""
    if not(row['thread'].startswith('pool')):
        pass

    # C##ARCSRC.CUSTOMER: filling column metadata...
    # SRC ORACLE: active connections: 0
    # DST ORACLE: active  connections: 0
        
    found = 
    if row['a_srcdst'].startswith("SRC"):
        row['a_srcdst']='SRC-TASK'    
    elif row['a_srcdst'].startswith("DST"):
        row['a_srcdst']='DST-TASK'    

def trdjoOracleSnapshotExtractor(row):
    """
    3 2023-08-30 13:37:46.484 DEBUG [pool-20-thread-1] t.r.d.j.o.OracleSnapshotExtractor: C##ARCSRC.DISTRICT: 4c3925b9-9300-467c-ac7b-dac0f96202ac (job finished) Duration: 00:00:00
    2 2023-08-30 13:37:34.308 DEBUG [pool-19-thread-2] t.r.d.j.o.OracleSnapshotExtractor: C##ARCSRC.OORDER chunk job count: 1
    2 2023-08-30 13:37:46.484 DEBUG [pool-20-thread-1] t.r.d.j.o.OracleSnapshotExtractor: C##ARCSRC.STOCK: c8b64646-3fba-45f3-87fe-42f9f13fb332 (creating job)        
    """
    table_desc=row['a_srcdst'].split(maxsplit=1)
    row['a_desc']=row['a_table']+" "+row['a_desc'] 
    row['a_table']=table_desc[0]
    row['a_srcdst']='SRC-TASK'

def trdjsSQLiteDatabase(row):
    if row['a_srcdst'].startswith("METADATA"):
        row['a_srcdst']='METADATA'    

tracelogParser={
    'trdjoOracleDatabase':trdjoOracleDatabase,
    'trdjoOracleSnapshotExtractor':trdjoOracleSnapshotExtractor,
    'trdExtractorTaskLogger':trdExtractorTaskLogger,
    'trdApplierTaskLogger':trdApplierTaskLogger,
    'trdjsSQLiteDatabase':trdjsSQLiteDatabase,
    'trMain':trMain,
}


def printThread(thread:dict):
    for key in sorted(thread):
        task=thread[key]
        try:
            print(f"{task['elapsed']} {task['a_thread']} {task['a_srcdst']} {task['a_table']} {task['a_cmd']} {task['a_desc']}")
        except:
            print(f"{task['elapsed']} {task['a_thread']} {task['a_srcdst']} {task['a_table']} {task['a_desc']}")

def process(line:str):
    global begin_time

    found = logger_re.match(line)
    if found is None:
        print(line)
    else:
        row=found.groupdict()
        print(row)
        exit()

    found = colon5.match(line)
    if found is None:
        found = colon4.match(line)
    if found is None:
        found = colon3.match(line)
    if found is None:
        found = colon2.match(line)

    if found is None:
        print(line)    
        exit()
    else:
        row=found.groupdict()
        row['a_srcdst'] = row['a_srcdst'].strip()
        row['a_table'] = row['a_table'].strip()
        # print(row)

        row_time = datetime.strptime(f"{row['a_year']}-{row['a_month']}-{row['a_day']} {row['an_hour']}:{row['a_minute']}:{row['a_second']}", '%Y-%m-%d %H:%M:%S.%f')
        print(row_time)
        if begin_time is None:
            begin_time = row_time

        time_diff = row_time - begin_time
        row['elapsed'] = time_diff

        logger_name=row['a_logger'].replace('.','')
        if logger_name in tracelogParser:
            tracelogParser[logger_name](row)
        else:
            logger_missing[logger_name]=line

        if row['a_srcdst'] == 'SRC-TASK':
            src_thread[row["a_thread"]]=row 
        elif row['a_srcdst'] == 'DST-TASK':
            dst_thread[row["a_thread"]]=row 
        elif row['a_srcdst'] == 'METADATA':
            meta_thread[row["a_thread"]]=row 
        else:
            oth_thread[row["a_thread"]]=row 
            
        click.clear()
        print("src")
        printThread(src_thread)
        print("dst")
        printThread(dst_thread)
        print("metadata")
        printThread(meta_thread)
        print("oth")
        printThread(oth_thread)
        print("missing")
        print(logger_missing)


import fileinput
for line in fileinput.input(encoding="utf-8"):
    process(line)

