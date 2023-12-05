#!/usr/bin/env bash

# fix dstat 
sudo service pmcd start

# need to remap dir first
/scripts/utils/init.d/volremap.sh
# then download
/scripts/utils/init.d/jdbc_download.sh 
# fixup permission on ramdisk / tmmpfs
/scripts/utils/init.d/tmpfsperm.sh 

# optional for x64 machines
TARGETARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)
case "${TARGETARCH}" in
    amd64) 
        /scripts/utils/init.d/install_db2_tools.sh
        /scripts/utils/init.d/install_oracle_tools.sh
        ;;
    arm64) 
        /scripts/utils/init.d/install_oracle_tools.sh
        echo "${TARGETARCH} does not support db2 tools"
        ;;
    *)
        echo "${TARGETARCH} does not support db2 and oracle tools"
        ;;
esac

# the rest
/scripts/utils/init.d/arclic.sh
/scripts/utils/init.d/tmux.sh 
ttyd tmux attach