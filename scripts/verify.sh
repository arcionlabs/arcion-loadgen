#!/usr/bin/env bash 

KEY=${1:-ycsb_key}
TABLE=${2:-usertable}
TMUX_SCREEN=${3:-4}            

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
. lib/jdbc_cli.sh

top10_query() {
    local KEY="$1"      # ycsb_key|id
    local TABLE="$2"    # usertable|sbtest1
    local X="$3"        # SRC|DST
    local TS2_SEL="$4"
    local TS2_ORD="$5"

    # use parameter expansion 
    # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    local DB_HOST=$( x="${X}DB_HOST"; echo ${!x} )
    local DB_PORT=$( x="${X}DB_PORT"; echo ${!x} )
    local DB_ARC_USER=$( x="${X}DB_ARC_USER"; echo ${!x} )
    local DB_ARC_PW=$( x="${X}DB_ARC_PW"; echo ${!x} )
    local DB_GRP=$( x="${X}DB_GRP"; echo ${!x} )
    local DB_JSQSH_DRIVER=$( x="${X}DB_JSQSH_DRIVER"; echo ${!x} )

    export DB_SELECT
    export DB_CLI

    case ${DB_GRP,,} in
        mysql)
            DB_SELECT="select $KEY,ts ${TS2_SEL} from $TABLE order by ts desc ${TS2_ORD}, $KEY asc limit 10\;"
            DB_CLI="mysql -t -u${DB_ARC_USER} -h${DB_HOST} -p${DB_ARC_PW} -D${DB_ARC_USER} -P${DB_PORT}"
        ;;
        postgresql)
            DB_SELECT="select $KEY,ts ${TS2_SEL} from $TABLE order by ts desc ${TS2_ORD}, $KEY asc limit 10\;"
            DB_CLI="psql postgresql://${DB_ARC_USER}:${DB_ARC_PW}@${DB_HOST}:${DB_PORT}/${DB_ARC_USER}"
        ;;
        sqlserver)
            if [ ! -z "${TS2_SEL}" ]; then TS2_SEL=',datediff(millisecond, ts2, ts2) as "ts2-ts1"'; fi
            DB_SELECT="select top 10 $KEY,ts ${TS2_SEL} from $TABLE order by ts desc ${TS2_ORD}, $KEY asc\;"
            DB_CLI="${JSQSH_DIR}/*/bin/jsqsh --driver=${DB_JSQSH_DRIVER} --user=${DB_ARC_USER} --password=${DB_ARC_PW} --server=${DB_HOST} --port=${DB_PORT} --database=${DB_ARC_USER}"
        ;;    
        *)
            echo "verify.sh: Error: ${DB_GRP} needs to be supported" >&2
            ;;
    esac
}

# .0 is source .1 is destination
tmux split-window -d -v -t :${TMUX_SCREEN}
if [ "$?" != "0" ]; then echo "could not split window"; exit 1; fi

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .0 does not exist"; exit 1; fi

ts2_exists=$( echo "\show columns -p ts2 $TABLE" | jdbc_cli_dst "-n -v headers=false -v footers=false" | awk -F'|' 'NF>1 {print $5}' )
if [ ! -z "${ts2_exists}" ]; then
    TS2_ORD=',ts2 desc'
    TS2_SEL=',ts2-ts as "ts2-ts"'
fi

# show lastest 10 the source
top10_query "$KEY" "$TABLE" "SRC"
srcdb_select=$DB_SELECT
srcdb_cli=$DB_CLI

top10_query "$KEY" "$TABLE" "DST" "$TS2_SEL" "$TS2_ORD" 
dstdb_select=$DB_SELECT
dstdb_cli=$DB_CLI

# start the CLI
tmux send-keys -t :$TMUX_SCREEN.0  "$srcdb_cli" enter
tmux send-keys -t :$TMUX_SCREEN.1  "$dstdb_cli" enter

# send the command every 1 second
while [ true ]; do
    tmux send-keys -t :$TMUX_SCREEN.0  C-l
    tmux send-keys -t :$TMUX_SCREEN.0  "$srcdb_select" enter
    tmux send-keys -t :$TMUX_SCREEN.1  C-l
    tmux send-keys -t :$TMUX_SCREEN.1  "$dstdb_select" enter
    sleep 1
done