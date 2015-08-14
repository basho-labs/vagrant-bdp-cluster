#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_test.sh"
source "$DIR/include_riak_client.sh"

# Riak node is writable
vagrant ssh riak1 -c "sudo riak-admin test"
# Cluster is committed, ring is distributed evenly
vagrant ssh riak1 -c "sudo riak-admin cluster status"
# Riak HTTP interface is listening
riak_delete "test" "foo"
riak_get "test" "foo"
assert "not found" "$RIAK_VALUE" "value at clean start"
riak_put "test" "foo" "bar"
riak_get "test" "foo"
RETRIES=5
while [[ $RETRIES > 0 ]]; do
    assert "bar" "$RIAK_VALUE" "value after put"
    if [[ $? == 0 ]]; then
        RETRIES=0
    else
        RETRIES=$((RETRIES - 1))
    fi
done
riak_delete "test" "foo"
riak_get "test" "foo"
assert "not found" "$RIAK_VALUE" "value after delete"
echo "Successfully tested Riak basic read/write"
