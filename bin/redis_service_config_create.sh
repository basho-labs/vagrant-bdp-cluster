#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

redis_port

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-redis redis HOST=\"0.0.0.0\" REDIS_PORT=\"$REDIS_PORT\""
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    break
done
