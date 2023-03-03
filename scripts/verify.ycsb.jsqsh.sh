#!/usr/bin/env bash 

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
. $(dirname "${BASH_SOURCE[0]}")/lib/jdbc_cli.sh

ycsb_top10_query() {
    local DB_GRP="$1"
    local TS2_SEL="$2"
    local TS2_ORD="$2"
    local DB_SELECT
    case ${DB_GRP,,} in
        mysql|postgresql)
            DB_SELECT="select ycsb_key,ts ${TS2_SEL} from usertable order by ts desc ${TS2_ORD}, ycsb_key asc limit 10;"
        ;;
        sqlserver)
            DB_SELECT="select top 10 select ycsb_key,ts ${TS2_SEL} from usertable order by ts desc ${TS2_ORD}, ycsb_key asc;"
        ;;    
        *)
            echo "Error: ${SRCDB_GRP} needs to be supproted" >&2
            ;;
    esac
    echo $DB_SELECT
}


# .0 is source .1 is destination
tmux split-window -d -v -t :4
if [ "$?" != "0" ]; then echo "could not split window"; exit 1; fi

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .0 does not exist"; exit 1; fi

SRCDB_SELECT=$( ycsb_top10_query $SRCDB_GRP )

if [ ! -z "$SRCDB_SELECT" ]; then
    tmux send-keys -t :4.0 ". /tmp/ini_menu.sh" enter
    tmux send-keys -t :4.0 "watch -n 1 \". lib/jdbc_cli.sh; echo '$SRCDB_SELECT' | jdbc_cli_src -n\"" enter
fi

# .0 is source .1 is destination
if [ "$?" != "0" ]; then echo "pane .1 does not exist"; exit 1; fi

echo "checking ts2"
ts2_exists=$( echo "\show columns -p ts2 ycsb" | jdbc_cli_dst -n -v headers=false -v footers=false | wc -l )
if [ "${ts2_exists}" = "3" ]; then
    TS2_ORD=',ts2 desc'
    TS2_SEL=',ts2-ts'
fi
DSTDB_SELECT=$( ycsb_top10_query "$DSTDB_GRP" "$TS2_SEL" "$TS2_ORD")

if [ ! -z "$DSTDB_SELECT" ]; then
    tmux send-keys -t :4.1 ". /tmp/ini_menu.sh" enter
    tmux send-keys -t :4.1 "watch -n 1 \". lib/jdbc_cli.sh; echo '$DSTDB_SELECT' | jdbc_cli_src -n\"" enter
fi