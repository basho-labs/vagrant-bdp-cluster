#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin services"
    break
done
