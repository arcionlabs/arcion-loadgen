#!/usr/bin/env -S awk -f
BEGIN {
  # options
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
  if (maxrealstalls==""){maxrealstalls=120};      # consecutive pg requires at leaset 120 before stream starts
  # constants
  snap_tally_begin=2
  snap_tally_end=2
  real_tally_begin=2
  real_tally_end=5
  # state machine
  last_repl_state=0
  repl_state=0
  snap_tally=0
  real_tally=0
  real_tally_inserted=0
  real_tally_updated=0
  real_tally_deleted=0
  real_tally_replaced=0
  real_tally_ddl=0

  # last non zero realtime tally
  last_real_tally_inserted=0
  last_real_tally_updated=0
  last_real_tally_deleted=0
  last_real_tally_replaced=0
  last_real_tally_ddl=0

  last_snap_tally=0
  last_real_tally=0

  # delta (TODO)
  delta_sec=0
  delta_applied=0
  delta_incoming=0 

  # used to checked progress when IDUR is not advancing
  snap_buffered_rows=0
  real_buffered_rows=0
  snap_buffered_rows_last=0
  real_buffered_rows_last=0
  last_buffered_rows=0
  buffered_rows=0
  # snap
  snap_success=0
  snap_sec=0
  empty_snaps=0
  snap_tbls=0
  snap_stalls=0
  # real
  real_sec=0
  empty_reals=0
  real_stalls=0
  real_tbls=0
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
  if (n==0) {emptystalls++; empty_snaps++; delta_snap_tally=0 } else {emptystalls=0; empty_snaps=0; snap_tbls=n; delta_snap_tally = snap_tally - last_snap_tally;} 
  delta_buffer_rows= buffered_rows - last_buffered_rows;
  # print "snap: " delta_snap_tally " " snap_tally " " emptystalls "," maxemptystalls "," maxemptystalls
  if (delta_snap_tally==0 && delta_buffer_rows==0) {emptystalls++; snap_stalls++;} else {emptystalls=0; snap_stalls=0;}
  # do not reset the last if bailing
  if (earlyexit != 0 && empty_snaps >= maxsnapempty) {exitcode=1; exit}; 
  if (earlyexit != 0 && snap_stalls >= maxsnapstalls) {exitcode=2; exit}; 
  if (earlyexit != 0 && emptystalls >= maxemptystalls) {exitcode=3; exit}; 
  # enable delta comparion by saving the current values
  if (n!=0) {
    last_snap_tally=snap_tally; snap_tally=0; last_buffered_rows=buffered_rows;
    real_tally=-last_snap_tally; # setup real delta calculation 
  }
  repl_state=0; 
  last_repl_state=repl_state
  next
  } # end of snap

/^$/ && repl_state==2 {
  # empty reset
  if (n==0) {emptystalls++; empyt_reals++; delta_real_tally=0;} else {emptystalls=0; empyt_reals=0; real_tbls=n; delta_real_tally = real_tally - last_real_tally;}  
  delta_buffer_rows= buffered_rows - last_buffered_rows;
  # stalls reset
  if (delta_real_tally==0 && delta_buffer_rows==0) {emptystalls++; real_stalls++;} else {emptystalls=0; real_stalls=0;} 
  # do not reset the last if bailing
  if (earlyexit != 0 && empty_reals >= maxrealempty) {exitcode=4; exit}; 
  if (earlyexit != 0 && real_stalls >= maxrealstalls) {exitcode=5; exit}; 
  if (earlyexit != 0 && emptystalls >= maxemptystalls) {exitcode=6; exit}; 
  # enable delta comparion by saving the current values
  if (n!=0) { 
    last_real_tally=real_tally; 
    last_real_tally_inserted=real_tally_inserted; 
    last_real_tally_deleted=real_tally_deleted; 
    last_real_tally_updated=real_tally_updated; 
    last_real_tally_replaced=real_tally_replaced; 
    last_buffered_rows=buffered_rows;

    real_tally=0; 
    real_tally_inserted=0; 
    real_tally_deleted=0; 
    real_tally_updated=0; 
    real_tally_replaced=0; 

    real_tally=-last_snap_tally
    real_tally_inserted=-last_snap_tally
  }
  last_repl_state=repl_state
  repl_state=0; 
  next
  } # end of real

# snapshot
/^Table name.*Rows/ {
  n=0; repl_state=1; snap_sec++; if (earlyexit != 0 && snap_sec>=maxsnapsecs) {exitcode=7; exit}
  next
  } 
  
  # 4 to 5 columns mean snapshot
repl_state==1 {
  snap_tally+=$2  #Rows 
  n++;
  } # DEBUG print $0

/^Elapsed time:.*Buffered Rows:/ { buffered_rows=$NF
  }

/^SUCCESS: Successfully replicated in SNAPSHOT mode/ {
  snap_success+=1
}

# realtime
/^Table name.*Insert/ {
  if ($8=="DDL") {real_ddl_enabled=1} else {real_ddl_enabled=0}
  n=0; repl_state=2; real_sec++; if (earlyexit != 0 && real_sec>=maxrealsecs) {exitcode=8; exit}
  next
  } 

repl_state==2 {
  real_tally+=$2; real_tally_inserted+=$2
  real_tally+=$3; real_tally_deleted+=$3
  real_tally+=$4; real_tally_updated+=$4
  real_tally+=$5; real_tally_replaced+=$5
  buffered_rows+=$6
  if (real_ddl_enabled){real_tally_ddl+=$7}
  n++
  } # DEBUG print $0

# count exit and resumes

/replicant exited with error code/ {
  if ($NF != 0) {
    errorresumes++; exited++; 
    if (earlyexit != 0 && (errorresumes>=maxexitresumes)) {exitcode=9; exit};
    if (earlyexit != 0 && (exited>=maxexit)) {exitcode=10; exit};
  }
} 

/Resuming replicant/ {
  errorresumes++; resuming++; 
  if (earlyexit != 0 && (errorresumes>=maxexitresumes)) {exitcode=11; exit}
  if (earlyexit != 0 && (resuming>=maxresume)) {exitcode=12; exit}
  } 

END {
  print exitcode "," earlyexit "," \
    snap_sec "," snap_tbls "," last_snap_tally ","  snap_success "," \
    real_sec "," real_tbls "," last_real_tally "," last_real_tally_inserted "," \
    last_real_tally_deleted "," last_real_tally_updated "," last_real_tally_replaced "," last_real_tally_ddl "," \
    delta_sec "," delta_applied "," delta_incoming "," \
    emptystalls "," empty_snaps ","  empty_reals "," snap_stalls "," real_stalls "," \
    errorresumes "," exited "," resuming
  if (DEBUG!="") {
  print "exit erly " \
    "ssec stbl  snaprows send " \
    "rsec rtbl  realrows rinserted rdeleted rupdated rreplaced rddl " \
    "dsec deltaapp deltaincm " \
    "emst semp remp sstl rstl " \
    "exrs exit resm"  >> "/dev/stderr" 
  printf "%4d %4d " \
    "%4d %4d %9d %4d " \
    "%4d %4d %9d %9d %8d %8d %9d %4d " \
    "%4d %8d %9d " \
    "%4d %4d %4d %4d %4d " \
    "%4d %4d %4d\n",  
    exitcode , earlyexit , \
    snap_sec , snap_tbls , last_snap_tally , snap_success ,  \
    real_sec , real_tbls , last_real_tally , last_real_tally_inserted , \
    last_real_tally_deleted , last_real_tally_updated , last_real_tally_replaced , last_real_tally_ddl , \
    delta_sec , delta_applied , delta_incoming , \
    emptystalls , empty_snaps ,  empty_reals , snap_stalls , real_stalls , \
    errorresumes , exited , resuming \
    >> "/dev/stderr"   
  }
  exit exitcode
}