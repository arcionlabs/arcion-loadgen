#!/usr/bin/env bash

sudo service pmcd start

# need to remap dir first
/scripts/utils/init.d/volremap.sh
# then download
/scripts/utils/init.d/jdbc_download.sh 

# optional for x64 machines
TARGETARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)
if [ "${TARGETARCH}" = "amd64" ]; then 
    /scripts/utils/init.d/install_db2_tools.sh
    /scripts/utils/init.d/install_oracle_tools.sh
else
    echo "${TARGETARCH} does not support db2 and oracle tools"
fi

# the rest
/scripts/utils/init.d/arclic.sh
/scripts/utils/init.d/tmux.sh 
ttyd tmux attach