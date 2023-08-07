#!/usr/bin/env -S awk -f
BEGIN {
  if (DEBUG=="") {DEBUG=1};
  if (earlyexit=="") {earlyexit=1};
  if (maxsnapsecs==""){maxsnapsecs=600};
  if (maxrealsecs==""){maxrealsecs=120};
  if (maxexitresumes==""){maxexitresumes=5};        # combine exits and resumes
  if (maxexit==""){maxexit=5};
  if (maxresume==""){maxresume=5}; 
  if (maxemptystalls=="") {maxemptystalls=120};   # combine empty and stalls
  if (maxsnapempty=="") {maxsnapempty=60};        # consecutive    
  if (maxrealempty=="") {maxrealempty=60};        # consecutive 
  if (maxsnapstalls==""){maxsnapstalls=60};       # consecutive 
  if (maxrealstalls==""){maxrealstalls=60};       # consecutive 
  snap_tally_begin=2
  snap_tally_end=2
  real_tally_begin=2
  real_tally_end=5
  # state machine
  last_repl_state=0
  repl_state=0
  snap_tally=0
  real_tally=0
  last_snap_tally=0
  last_real_tally=0
  last_buffered_rows=0
  buffered_rows=0
  # snap
  snap=0
  empty_snaps=0
  snap_rows=0
  snap_stalls=0
  # real
  real=0
  empty_reals=0
  real_stalls=0
  real_rows=0
  # resmt and exit
  resuming=0
  exited=0
  # combination counter
  emptystalls=0
  errorresumes=0
  # exit code
  exitcode=0
}
/^_+$/ {
  next} 

/^$/ && repl_state==1 {
  if (n==0) {emptystalls++; empty_snaps++;} 
  else {emptystalls=0; empty_snaps=0; snap_rows=n;} 
  delta_snap_tally = snap_tally - last_snap_tally; 
  delta_buffer_rows= buffered_rows - last_buffered_rows;
  # print "snap: " delta_snap_tally " " snap_tally " " emptystalls "," maxemptystalls "," maxemptystalls
  if (delta_snap_tally==0 && delta_buffer_rows==0) {emptystalls++; snap_stalls++;}  
  else {emptystalls=0; snap_stalls=0;}
  if (earlyexit != 0 && empty_snaps >= maxsnapempty) {exitcode=1; exit}; 
  if (earlyexit != 0 && snap_stalls >= maxsnapstalls) {exitcode=2; exit}; 
  if (earlyexit != 0 && emptystalls >= maxemptystalls) {exitcode=3; exit}; 
  repl_state=0; last_snap_tally=snap_tally; snap_tally=0; last_buffered_rows=buffered_rows;
  real_tally=-last_snap_tally; # setup real delta calculation 
  last_repl_state=repl_state
  next
  } # end of snap

/^$/ && repl_state==2 {
  # empty reset
  if (n==0) {emptystalls++; empyt_reals++;} 
  else {emptystalls=0; empyt_reals=0; real_rows=n;} 
  delta_real_tally = real_tally - last_real_tally; 
  delta_buffer_rows= buffered_rows - last_buffered_rows;
  # stalls reset
  if (delta_real_tally==0 && delta_buffer_rows==0) {emptystalls++; real_stalls++;}  
  else {emptystalls=0; real_stalls=0;} 
  if (earlyexit != 0 && empty_reals >= maxrealempty) {exitcode=4; exit}; 
  if (earlyexit != 0 && real_stalls >= maxrealstalls) {exitcode=5; exit}; 
  if (earlyexit != 0 && emptystalls >= maxemptystalls) {exitcode=6; exit}; 
  repl_state=0; last_real_tally=real_tally; real_tally=-last_snap_tally; last_buffered_rows=buffered_rows;
  last_repl_state=repl_state
  next
  } # end of real

repl_state==1 {
  sum=0; for (i=snap_tally_begin;i<=snap_tally_end;i++){sum+=$i}; snap_tally+=sum; n++;
  } # DEBUG print $0

/^Elapsed time:.*Buffered Rows:/ { buffered_rows=$NF
  }

repl_state==2 {
  sum=0; for (i=real_tally_begin;i<=real_tally_end;i++){sum+=$i}; real_tally+=sum;n++;
  buffered_rows+=$6
  } # DEBUG print $0

/^Table name.*Rows/ {
  n=0; repl_state=1; snap++; if (earlyexit != 0 && snap>=maxsnapsecs) {exitcode=7; exit}} 

/^Table name.*Insert/ {
  n=0; repl_state=2; real++; if (earlyexit != 0 && real>=maxrealsecs) {exitcode=8; exit}} 

/replicant exited with error code/ {
  errorresumes++; exited++; 
  if (earlyexit != 0 && (errorresumes>=maxexitresumes)) {exitcode=9; exit};
  if (earlyexit != 0 && (exited>=maxexit)) {exitcode=10; exit};
  } 

/Resuming replicant/ {
  errorresumes++; resuming++; 
  if (earlyexit != 0 && (errorresumes>=maxexitresumes)) {exitcode=11; exit}
  if (earlyexit != 0 && (resuming>=maxresume)) {exitcode=12; exit}
  } 

END {
  print exitcode "," earlyexit "," snap_rows "," real_rows ","   snap ","  real "," last_snap_tally "," last_real_tally "," emptystalls "," empty_snaps ","  empty_reals "," snap_stalls "," real_stalls "," errorresumes "," exited "," resuming
  if (DEBUG!="") {
  print  "exit erly srows rrows snaps reals snaptally realtally emst snem rlem snst rlst errs exit rsmn"  >> "/dev/stderr"
  printf "%4d %4d %5d %5d %5d %5d %9d %9d %4d %4d %4d %4d %4d %4d %4d %4d\n",
    exitcode,earlyexit,snap_rows,real_rows,snap,real,last_snap_tally,last_real_tally,emptystalls,empty_snaps,empty_reals,snap_stalls,real_stalls,errorresumes,exited,resuming >> "/dev/stderr"
  }
  exit exitcode
}