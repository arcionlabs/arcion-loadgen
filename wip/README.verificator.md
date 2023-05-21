CFGDIR=$( ls -t /tmp/arcion | head -n 1 )
CFGDIR=/tmp/arcion/$CFGDIR

cat $CFGDIR/src.yaml | grep -v "^slave" > $CFGDIR/src.verificator.yaml

./bin/replicate-row-verificator verify \
$CFGDIR/src.verificator.yaml \
$CFGDIR/dst.yaml \
--filter $CFGDIR/src_filter.yaml \
--map $CFGDIR/dst_map.yaml \
--id $$

--filter filter/sqlserver_filter.yaml --map mapper/sqlserver_to_memsql.yaml --id ver1