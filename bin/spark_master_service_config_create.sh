#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

if [[ "$OSS" -eq 1 ]]; then
    # OSS supports a single spark master
    : #<< NOP
else
    riak_leader_election_port
    vagrant_ips $TARGET_VM_COUNT $RIAK_LEADER_ELECTION_PORT ','
    LEADER_ELECTION_SERVICE_IPS="$VAGRANT_IPS"
fi

riak_pb_port
vagrant_ips $TARGET_VM_COUNT $RIAK_PB_PORT ','
RIAK_KV_IPS="$VAGRANT_IPS"

IP_LSD=1
vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    let IP_LSD+=1

    if [[ "$OSS" -eq 1 ]]; then
        vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-spark-master spark-master RIAK_HOSTS=\"$RIAK_KV_IPS\""
    else
        vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-spark-master spark-master LEAD_ELECT_SERVICE_HOSTS=\"$LEADER_ELECTION_SERVICE_IPS\" RIAK_HOSTS=\"$RIAK_KV_IPS\""
    fi
    EXIT_CODE=$?
    if [[ $EXIT_CODE != 0 ]]; then
        exit $EXIT_CODE
    fi
    break
done
