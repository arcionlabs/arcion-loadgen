#!/usr/env/bin python3

from typing import List

sfs=("-s 1 -w 1200:300")  # -s scale -w wait 1200 snap 500 real-time
threads=("-b 1:1 -c 1:1 -r 0")    # -b snap ext thread 1 applier 1 -c real-time ext thread 1 applier 1 -r workload tps max

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
              # SRCDB_DB=arcsrc ./arcdemo.sh $sf $t $r $s $d
          done
        done
      done
    done
  done

if __name__ == "__main__":
    loop_run(["snapshot","full"], ["ase"], ["oraee"])