#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}
TARGET_VAGRANT_NAME=$2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    echo "type the following into the attached console: riak_ensemble_manager:enable().<ENTER>^Gq"
    vagrant ssh $VAGRANT_NAME -c 'sudo riak attach'
    # SHOULD BE: vagrant ssh $VAGRANT_NAME -c 'echo "riak_ensemble_manager:enable()." |sudo riak attach'
    break
done
