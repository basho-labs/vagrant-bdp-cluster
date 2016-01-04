#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"
source "$DIR/include_test.sh"
source "$DIR/include_riak_client.sh"
source "$DIR/include_redis_client.sh"
source "$DIR/include_cache_proxy_client.sh"

cache_ttl

# Riak node is writable
vagrant ssh riak1 -c "sudo riak-admin test"
# Cluster is committed, ring is distributed evenly
vagrant ssh riak1 -c "sudo riak-admin cluster status"

riak_delete "test" "foo"
riak_get "test" "foo"
assert_exit "not found" "$RIAK_VALUE" "riak value at clean start"
riak_put "test" "foo" "bar"
RETRIES=5
while [[ $RETRIES > 0 ]]; do
    riak_get "test" "foo"
    assert "bar" "$RIAK_VALUE" "riak value after put"
    if [[ $? == 0 ]]; then
        RETRIES=0
    else
        RETRIES=$((RETRIES - 1))
    fi
done
cache_proxy_get 0 "test:foo"
assert_exit "bar" "$CACHE_PROXY_VALUE" "cache-proxy value via read-through"
redis_spanning_get "test:foo"
echo "sleeping for $CACHE_TTL to test expiry"
sleep $CACHE_TTL
for i in `seq 1 $TARGET_VM_COUNT`; do
    let INDEX=$i-1
    redis_get $INDEX "test:foo"
    assert_exit "" "$REDIS_VALUE" "redis value from $INDEX after expiry"
done

riak_delete "test" "foo"
riak_get "test" "foo"
assert_exit "not found" "$RIAK_VALUE" "riak value after delete"
echo "sleeping for $CACHE_TTL to await eventual consistency"
sleep $CACHE_TTL
sleep 1
cache_proxy_get 0 "test:foo"
assert_exit "" "$CACHE_PROXY_VALUE" "cache-proxy value after riak delete"
for i in `seq 1 $TARGET_VM_COUNT`; do
    let INDEX=$i-1
    redis_get $INDEX "test:foo"
    assert_exit "" "$REDIS_VALUE" "redis value from $INDEX after riak delete"
done
echo "Successfully tested Cache Proxy read-through"
