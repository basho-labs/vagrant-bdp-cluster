#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

if [[ $RIAK_HEAD_IP == "" ]]; then
    vagrant_ips 1
    RIAK_HEAD_IP=$VAGRANT_IPS
fi
riak_http_port

function riak_get () {
    local BUCKET=${1:-test}
    local KEY=${2:-foo}
    RIAK_VALUE=$(curl -s "http://$RIAK_HEAD_IP:$RIAK_HTTP_PORT/buckets/$BUCKET/keys/$KEY")
}
function riak_put () {
    local BUCKET=${1:-test}
    local KEY=${2:-foo}
    local VALUE=$3
    curl -s -X PUT -d "$VALUE" "http://$RIAK_HEAD_IP:$RIAK_HTTP_PORT/buckets/$BUCKET/keys/$KEY"
}
function riak_delete () {
    local BUCKET=${1:-test}
    local KEY=${2:-foo}
    curl -s -X DELETE "http://$RIAK_HEAD_IP:$RIAK_HTTP_PORT/buckets/$BUCKET/keys/$KEY"
}
