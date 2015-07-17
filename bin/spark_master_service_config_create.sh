#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

riak_leader_election_port
vagrant_ips $TARGET_VM_COUNT $RIAK_LEADER_ELECTION_PORT ','
LEADER_ELECTION_SERVICE_IPS="$VAGRANT_IPS"

riak_pb_port
vagrant_ips $TARGET_VM_COUNT $RIAK_PB_PORT ','
RIAK_KV_IPS="$VAGRANT_IPS"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-spark-master spark-master LEAD_ELECT_SERVICE_HOSTS=\"$LEADER_ELECTION_SERVICE_IPS\" RIAK_HOSTS=\"$RIAK_KV_IPS\""
    break
done
