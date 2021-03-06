#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}
CONTROL_COMMAND=$1
SERVICE_GROUP=$2
SERVICE_CONFIG=$3
TARGET_VAGRANT_NAME=$4

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

function usage () {
    cat <<EOF
usage: $0 CONTROL_COMMAND SERVICE_GROUP SERVICE_CONFIG

CONTROL_COMMAND supports:
    start
    stop
    get-pid

SERVICE_GROUP is a group name that you elect, ie "my-spark-group"

SERVICE_CONFIG supports:
    my-cache-proxy
    my-redis
    my-spark-master
    my-spark-worker
EOF
}

if [[ $SERVICE_GROUP == "" || $SERVICE_CONFIG == "" ]]; then
    usage
    exit 1
fi

case $CONTROL_COMMAND in
    start)
        CONTROL_COMMAND="start-service"
        ;;
    stop)
        CONTROL_COMMAND="stop-service"
        ;;
    get-pid)
        : #<<NOP
        ;;
    *)
        usage
        exit 1
        ;;
esac

function ps_line () {
    local VAGRANT_NAME_=$1
    local SERVICE_CONFIG=$2

    case $SERVICE_CONFIG in
        my-cache-proxy)
            PROCESS_PATTERN="[n]utcracker"
            ;;
        my-redis)
            PROCESS_PATTERN="[r]edis"
            ;;
        my-spark-master)
            PROCESS_PATTERN="[s]park-master"
            ;;
        my-spark-worker)
            PROCESS_PATTERN="[s]park-worker"
            ;;
        *)
            return 1
    esac

    PS_LINE=$(vagrant ssh $VAGRANT_NAME_ -c "sudo ps aux |grep $PROCESS_PATTERN")
}

function process_pid () {
    local VAGRANT_NAME_=$1
    local SERVICE_CONFIG=$2

    ps_line $VAGRANT_NAME_ $SERVICE_CONFIG
    PROCESS_PID=$(echo $PS_LINE |awk '{print $2}')
}

function kill_service_process () {
    local VAGRANT_NAME_=$1
    local SERVICE_CONFIG=$2

    process_pid $VAGRANT_NAME_ $SERVICE_CONFIG
    if [[ $PROCESS_PID != "" ]]; then
        vagrant ssh $VAGRANT_NAME_ -c "sudo kill $PROCESS_PID"
    fi
}

vagrant_names $TARGET_VM_COUNT
NODE_NUMBER=0
PIDS_MISSING=0
for VAGRANT_NAME in $VAGRANT_NAMES; do
    let NODE_NUMBER+=1
    riak_node_name $NODE_NUMBER

    if [[ "$TARGET_VAGRANT_NAME" != "" && "$TARGET_VAGRANT_NAME" != "$VAGRANT_NAME" ]]; then
        continue
    fi

    if [[ $CONTROL_COMMAND == "get-pid" ]]; then
        process_pid $VAGRANT_NAME $SERVICE_CONFIG
        if [[ $PROCESS_PID == "" ]]; then
            let PIDS_MISSING+=1
        fi
        echo "$VAGRANT_NAME $PROCESS_PID"
    else
        vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin $CONTROL_COMMAND \"$RIAK_NODE_NAME\" $SERVICE_GROUP $SERVICE_CONFIG"
        EXIT_CODE=$?
        if [[ $EXIT_CODE != 0 ]]; then
            exit $EXIT_CODE
        fi
    fi
done

if [[ $CONTROL_COMMAND == "get-pid" ]]; then
    if [[ $PIDS_MISSING > 0 ]]; then
        echo "Some pids were missing, you may want to stop and start the service."
        exit $PIDS_MISSING
    fi
fi
