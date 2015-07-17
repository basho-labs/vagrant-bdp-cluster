#! /bin/bash
TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

cache_proxy_port
cache_proxy_stats_port
cache_ttl

redis_port
vagrant_ips $TARGET_VM_COUNT $REDIS_PORT ','
REDIS_IPS="$VAGRANT_IPS"

riak_pb_port
vagrant_ips $TARGET_VM_COUNT $RIAK_PB_PORT ','
RIAK_KV_IPS="$VAGRANT_IPS"

vagrant_names $TARGET_VM_COUNT
for VAGRANT_NAME in $VAGRANT_NAMES; do
    vagrant ssh $VAGRANT_NAME -c "sudo data-platform-admin add-service-config my-cache-proxy cache-proxy HOSTS=\"0.0.0.0\" CACHE_PROXY_PORT=\"$CACHE_PROXY_PORT\" CACHE_PROXY_STATS_PORT=\"$CACHE_PROXY_STATS_PORT\" CACHE_TTL=\"$CACHE_TTL\" RIAK_KV_SERVERS=\"$RIAK_KV_IPS\" REDIS_SERVERS=\"$REDIS_IPS\""
    break
done
