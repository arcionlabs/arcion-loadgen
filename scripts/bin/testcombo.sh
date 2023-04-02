#!/usr/bin/env bash

src="${1:-mysql postgresql mariadb sqlserver informix}"
dst="${2:-mysql2 postgresql}"
repl="${3:-snapshot delta-snapshot real-time full}"
for s in $src; do
  for d in $dst; do
    for r in $repl; do
        echo "./arcdemo.sh -w 60 $r $s $d"
        ./arcdemo.sh -w 60 $r $s $d
        #$SCRIPTS_DIR/bin/validate.sh
    done
  done
done

echo "Looking for runs had data validation error"
find /tmp/arcion -type f -name "*.diff" -size +0c