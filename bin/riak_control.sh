#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}
CONTROL_COMMAND=$1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

function usage () {
    cat <<EOF
usage: $0 CONTROL_COMMAND

CONTROL_COMMAND supports:
    riak
        ping
        restart
        start
        stop
    riak-admin
        cluster-status
        ensemble-status
EOF
}

case $CONTROL_COMMAND in
    ping|restart|start|stop)
        RIAK_EXE=riak
        ;;
    cluster-status|ensemble-status)
        RIAK_EXE=riak-admin
        ONCE="true"
        ;;
    *)
        usage
        exit 1
        ;;
esac

case $CONTROL_COMMAND in
    cluster-status)
        CONTROL_COMMAND="cluster status"
        ;;
esac

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo $RIAK_EXE $CONTROL_COMMAND"
    if [[ $ONCE != "" ]]; then break; fi
done
