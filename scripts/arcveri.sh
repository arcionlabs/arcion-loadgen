#!/usr/bin/env bash 

CFGDIR=$1

if [ -z "${CFGDIR}" ]; then
    CFGDIR=$( ls -t /tmp/arcion | head -n 1 )
    CFGDIR=/tmp/arcion/$CFGDIR
fi

# pickup LOGID of the replication
. $CFGDIR/ini_menu.sh

if [ -z "$LOG_ID" ]; then LOG_ID=$$; fi

# remove realtime params
cat $CFGDIR/src.yaml | grep -v -e "^slave" > $CFGDIR/src.verificator.yaml

# run 
pushd $VERIFICATOR_HOME
./bin/replicate-row-verificator verify \
$CFGDIR/src.verificator.yaml \
$CFGDIR/dst.yaml \
--filter $CFGDIR/src_filter.yaml \
--map $CFGDIR/src_map.yaml \
--id $LOG_ID
popd >/dev/null

# 
echo "Review $CFGDIR and $VERIFICATOR_HOME/data/$LOG_ID" 