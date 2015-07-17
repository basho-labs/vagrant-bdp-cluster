#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type create strong '{\"props\":{\"consistent\":true}}'"
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type create maps '{\"props\":{\"datatype\":\"map\"}}'"
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type activate maps"
    vagrant ssh $VAGRANT_NAME -c "sudo riak-admin bucket-type status maps"
    break
done
