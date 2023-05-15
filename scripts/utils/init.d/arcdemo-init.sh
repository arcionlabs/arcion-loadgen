#!/usr/bin/env bash

# need to remap dir first
/scripts/utils/init.d/volremap.sh

# optional for x64 machines
# WIP /scripts/utils/db2_pkg.sh
/scripts/utils/init.d/arclic.sh
/scripts/utils/init.d/jdbc_download.sh 
/scripts/utils/init.d/tmux.sh 
ttyd tmux attach