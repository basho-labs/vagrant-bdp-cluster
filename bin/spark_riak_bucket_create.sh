#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type create strong '{\"props\":{\"consistent\":true}}'"
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type create maps '{\"props\":{\"datatype\":\"map\"}}'"
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type activate maps"
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type status maps"
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    break
done
