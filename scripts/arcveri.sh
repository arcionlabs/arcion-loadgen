#!/usr/bin/env bash 

CFGDIR=$1

if [ -z "${CFGDIR}" ]; then
    CFGDIR=$( ls -t /tmp/arcion | head -n 1 )
    CFGDIR=/tmp/arcion/$CFGDIR
fi

# pickup LOGID of the replication
. $CFGDIR/ini_menu.sh
. lib/jdbc_cli.sh

if [ -z "$LOG_ID" ]; then LOG_ID=$$; fi

# remove realtime params
# type must be upper case
# mysql as group works
cat $CFGDIR/src.yaml | \
    grep -v -e "^slave" -e "^extractor" | \
    sed "s/^type: \(.*\)/type: ${SRCDB_GRP^^}/i" > $CFGDIR/src.verificator.yaml
    
cat $CFGDIR/dst.yaml | \
    sed "s/^type: \(.*\)/type: ${DSTDB_GRP^^}/i" > $CFGDIR/dst.verificator.yaml

# remove ts2 from destination to match the source
# TODO: 
#  compare src and dst and 
#  drop column on dst not on the source
#  add column to dst not on the source
cat <<EOF | jdbc_cli_dst
-- for all destionations
alter table usertable drop column ts2;
alter table sbtest1 drop column ts2;
-- only for postgresql destinations
drop trigger update_ts2_on_usertable_on on usertable;
drop trigger update_ts2_on_sbtest1_on on sbtest1;
EOF

# run 
pushd $VERIFICATOR_HOME
./bin/replicate-row-verificator verify \
$CFGDIR/src.verificator.yaml \
$CFGDIR/dst.verificator.yaml \
--filter $CFGDIR/src_filter.yaml \
--map $CFGDIR/src_map.yaml \
--id $LOG_ID
popd >/dev/null

# 
echo "Review $CFGDIR and $VERIFICATOR_HOME/data/$LOG_ID" 