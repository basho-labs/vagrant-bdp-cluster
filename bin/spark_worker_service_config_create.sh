#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

spark_master_port
spark_worker_port
vagrant_ips $TARGET_VM_COUNT $SPARK_MASTER_PORT ','
SPARK_MASTER_URL="spark://$VAGRANT_IPS"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-spark-worker spark-worker MASTER_URL=\"$SPARK_MASTER_URL\" SPARK_WORKER_PORT=\"$SPARK_WORKER_PORT\""
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    break
done
