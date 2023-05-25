#!/usr/bin/env bash 

# this file should be in $YCSB/bin dir

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}

. $SCRIPTS_DIR/lib/classpath.sh

CLASSPATH=$(arcion_jdbc_jars)

echo "YCSB CLASSPATH=$CLASSPATH" >&2