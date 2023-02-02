#!/usr/bin/env bash 

# standard source id / password 
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}
DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcsrc}
DSTDB_ARC_PW=${DSTDB_ARC_PW:-password}

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/ini_jdbc.sh
echo $SRC_JDBC_DRIVER
echo $SRC_JDBC_URL

# .0 is source .1 is destination
tmux split-window -d -h -t :3
if [ "$?" != "0" ]; then echo "could not split window"; exit 1; fi

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .0 does not exist"; exit 1; fi

case ${SRCDB_TYPE,,} in
    mysql|mariadb|singlestore)
        echo ${SRCDB_HOST} ${SRCDB_TYPE}    
        tmux send-keys -t :3.0 "watch -n 1 \"mysql -t -u${SRCDB_ARC_USER} -h${SRCDB_HOST} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -e 'select id,ts from sbtest1 order by ts desc,id asc limit 20;'\"" enter
    ;;
    postgresql|cockroach)
        echo ${SRCDB_HOST} ${SRCDB_TYPE}    
        ;; 
    *)
        echo "Error: ${DSTDB_TYPE} needs to be supproted"
        ;;
esac

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .1 does not exist"; exit 1; fi

case ${DSTDB_TYPE,,} in
    mysql|mariadb|singlestore)
        echo ${DSTDB_HOST} ${DSTDB_TYPE}    
        tmux send-keys -t :3.1 "watch -n 1 \"mysql -t -u${DSTDB_ARC_USER} -h${DSTDB_HOST} -p${DSTDB_ARC_PW} -D${DSTDB_ARC_USER} -e 'select id,ts from sbtest1 order by ts desc,id asc limit 20;'\"" enter
    ;;
    postgresql|cockroach)
        echo ${DSTDB_HOST} ${DSTDB_TYPE}    
        ;; 
    *)
        echo "Error: ${DSTDB_TYPE} needs to be supproted"
        ;;
esac
