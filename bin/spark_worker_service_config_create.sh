#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

spark_master_port
vagrant_ips $TARGET_VM_COUNT $SPARK_MASTER_PORT ','
SPARK_MASTER_URL="spark://$VAGRANT_IPS"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-spark-worker spark-worker MASTER_URL=\"$SPARK_MASTER_URL\""
    break
done
