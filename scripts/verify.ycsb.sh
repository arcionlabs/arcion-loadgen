#!/usr/bin/env bash 

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

# .0 is source .1 is destination
tmux split-window -d -v -t :4
if [ "$?" != "0" ]; then echo "could not split window"; exit 1; fi

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .0 does not exist"; exit 1; fi

case ${SRCDB_TYPE,,} in
    mysql|mariadb|singlestore)
        tmux send-keys -t :4.0 "watch -n 1 \"mysql -t -u${SRCDB_ARC_USER} -h${SRCDB_HOST} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -P${SRCDB_PORT} -e 'select ycsb_key,ts from usertable order by ts desc,ycsb_key asc limit 10;'\"" enter
    ;;
    postgresql|cockroach)
        tmux send-keys -t :4.0 "watch -n 1 \"psql postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} -c 'select ycsb_key,ts from usertable order by ts desc,ycsb_key asc limit 10;'\"" enter
        ;; 
    sqlserver)
        echo ${SRCDB_HOST} ${SRCDB_TYPE}    
        tmux send-keys -t :3.0 "watch -n 1 \"echo 'select top 10 select ycsb_key,ts from usertable order by ts desc,ycsb_key asc;' | ${JSQSH_DIR}/*/bin/jsqsh --driver=${SRCDB_JSQSH_DRIVER} --user=${SRCDB_ARC_USER} --password=${SRCDB_ARC_PW} --server=${SRCDB_HOST} --port=${SRCDB_PORT} --database=${SRCDB_ARC_USER}\"" enter        
        ;;         
    *)
        echo "Error: ${DSTDB_TYPE} needs to be supproted"
        ;;
esac

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .1 does not exist"; exit 1; fi

echo target ${DSTDB_HOST} ${DSTDB_TYPE}
case ${DSTDB_TYPE,,} in
    mysql|mariadb|singlestore)
        # ts2 exists? 
        echo "checking ts2"
        [ ! -z "$( mysql -t -u${DSTDB_ARC_USER} -h${DSTDB_HOST} -p${DSTDB_ARC_PW} -D${DSTDB_ARC_USER} -P${DSTDB_PORT} -e 'desc sbtest1' | grep ts2 )" ] && TS2_ORD=',ts2 desc' && TS2_SEL=',ts2-ts'
        echo "running watch"
        # watch w/ mysql
        tmux send-keys -t :4.1 "watch -n 1 \"mysql -t -u${DSTDB_ARC_USER} -h${DSTDB_HOST} -p${DSTDB_ARC_PW} -D${DSTDB_ARC_USER} -P${DSTDB_PORT} -e 'select ycsb_key,ts ${TS2_SEL} from usertable order by ts desc ${TS2_ORD}, ycsb_key asc limit 20;'\"" enter
    ;;
    postgresql|cockroach)
        tmux send-keys -t :4.1 "watch -n 1 \"psql postgresql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER} -c 'select ycsb_key,ts from usertable order by ts desc,ycsb_key asc limit 20;'\"" enter        
        ;; 
    sqlserver)
        tmux send-keys -t :4.1 "watch -n 1 \"echo 'select top 10 ycsb_key,ts from usertable order by ts desc,ycsb_key asc;' | ${JSQSH_DIR}/*/bin/jsqsh --driver=${DSTDB_JSQSH_DRIVER} --user=${DSTDB_ARC_USER} --password=${DSTDB_ARC_PW} --server=${DSTDB_HOST} --port=${DSTDB_PORT} --database=${DSTDB_ARC_USER}\"" enter             
        ;;         
    *)
        echo "Error: ${DSTDB_TYPE} needs to be supproted"
        ;;
esac
