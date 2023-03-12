#!/usr/bin/env bash

src="mysql postgresql"
dst="mysql2 postgresql"
repl="snapshot delta-snapshot real-time full"
for s in $src; do
  for d in $dst; do
    for r in $repl; do
        ./arcdemo.sh -w 60 $r $s $d
        ./validate.sh
    done
  done
done

echo "the following runs had data validation error"
find /tmp/arcion -type f -name "*.diff" -size +0c