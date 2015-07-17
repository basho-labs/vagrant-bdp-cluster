#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

if [[ $TARGET_VM_COUNT > 1 ]]; then
    vagrant_names $TARGET_VM_COUNT
    VAGRANT_HEAD=""
    for VAGRANT_NAME in $VAGRANT_NAMES; do
        if [[ $VAGRANT_HEAD == "" ]]; then
            VAGRANT_HEAD=$VAGRANT_NAME
            riak_node_name 1
            RIAK_NODE_NAME_HEAD=$RIAK_NODE_NAME
        else
            vagrant ssh $VAGRANT_NAME -c "sudo riak-admin cluster join $RIAK_NODE_NAME_HEAD"
        fi
    done
    vagrant ssh $VAGRANT_HEAD -c "sudo riak-admin cluster plan && sudo riak-admin cluster commit"
fi
