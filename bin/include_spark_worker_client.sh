#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

spark_master_port
vagrant_names $TARGET_VM_COUNT
vagrant_ips $TARGET_VM_COUNT $SPARK_MASTER_PORT
VAGRANT_NAMES_ARRAY=($VAGRANT_NAMES)
SPARK_MASTER_IPS_ARRAY=($VAGRANT_IPS)
SPARK_MASTER_URL=$(echo "spark://$VAGRANT_IPS" |sed 's/ /,/g')

function spark_worker_nth_vagrant () {
    local INDEX=$1
    SPARK_WORKER_VAGRANT=${VAGRANT_NAMES_ARRAY[$INDEX]}
}

function spark_worker_random_vagrant () {
    local INDEX=$((RANDOM%TARGET_VM_COUNT))
    spark_worker_nth_vagrant $INDEX
}

function spark_worker_submit () {
    local INDEX="$1"
    if [[ "$INDEX" == "" || $INDEX -lt 0 || "$INDEX" -ge $TARGET_VM_COUNT ]]; then
        >&2 echo "spark_worker_submit index out of bounds, $INDEX is not within the range [0..${TARGET_VM_COUNT})"
        SPARK_WORKER_RESPONSE=""
        return
    fi
    local SOURCE_FILE="$2"
    if [[ ! $SOURCE_FILE =~ "^/" ]]; then
        SOURCE_FILE="$BDP_PRIV/spark-worker/$SOURCE_FILE"
    fi
    shift 2
    local SPARK_WORKER_ARGS="$@"
    spark_worker_nth_vagrant $INDEX
    SPARK_WORKER_RESPONSE=$(vagrant ssh $SPARK_WORKER_VAGRANT -c "$BDP_PRIV/spark-worker/bin/spark-submit --master \"$SPARK_MASTER_URL\" \"$SOURCE_FILE\" $SPARK_WORKER_ARGS" 2>/dev/null)
}

