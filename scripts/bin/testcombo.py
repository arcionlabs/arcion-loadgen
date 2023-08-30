#!/usr/bin/env python3

from typing import List
import subprocess

all_cdc=['ase',,'db2',,'informix',,'mariadb',,'mysql',,'oraee',,'oraxe','pg',,'sqlserver']
all_src=['ase','cockroach','db2','informix','mariadb','mysql','oraee','oraxe','pg','s2','sqledge','sqlserver','yugabytesql']
all_dst=['cockroach','informix','kafka','mariadb','minio','mysql','null','oraee','pg','redis','s2','sqledge','sqlserver','yugabytesql']
cloud_src=['snowflake','gcs','gcsm','gcsp','gcss','gasa']
cloud_dst=['snowflake','gcs','gcsm','gcsp','gcss','gasa']

def loop_run(
    repl:List[str], 
    src:List[str], 
    dst:List[str], 
    sfs:List[str] = ["-s 1 -w 1200:300"], 
    threads:List[str] = ["-b 1:1 -c 1:1 -r 0"]):

  for sf in sfs:
    for t in threads: 
      for r in repl:
        for s in src:
          for d in dst:
              print(f"./arcdemo.sh {sf} {t} {r} {s} {d}")
              p = subprocess.run(f"SRCDB_DB=arcsrc test.sh ${sf} ${t} ${r} ${s} ${d}", shell=True, capture_output=True, text=True)
              print(p.stdout)

if __name__ == "__main__":
    loop_run(["snapshot","full"], ["ase"], ["oraee"])