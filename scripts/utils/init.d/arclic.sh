#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
ARCION_LIC=${ARCION_LIC:-/opt/stage/libs}

echo "Checking replicant.lic" 

if [ -f "${ARCION_LIC}/replicant.lic" ]; then
    echo "${ARCION_LIC}/replicant.lic exists. skipping replicant.lic setup"

elif [ -z "${ARCION_LICENSE}" ]; then 
    echo "ARCION_LICENSE is blank.  skipping replicant.lic  setup."

else
    echo "setting ${ARCION_LIC}/replicant.lic from \$ARCION_LICENSE"
    # try if gzip
    echo "$ARCION_LICENSE" | base64 -d | gzip -d > ${ARCION_LIC}/replicant.lic 2>/dev/null
    # try non gzip
    if [ "$?" != 0 ]; then
        echo "$ARCION_LICENSE" | base64 -d > ${ARCION_LIC}/replicant.lic
    fi
fi

cat ${ARCION_LIC}/replicant.lic
