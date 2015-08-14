#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

cache_proxy_port
vagrant_names $TARGET_VM_COUNT
vagrant_ips $TARGET_VM_COUNT $CACHE_PROXY_PORT
VAGRANT_NAMES_ARRAY=($VAGRANT_NAMES)
CACHE_PROXY_IPS_ARRAY=($VAGRANT_IPS)

REDIS_CLI=${REDIS_CLI:-"$(which redis-cli)"}

function cache_proxy_nth_vagrant () {
    local INDEX=$1
    CACHE_PROXY_VAGRANT=${VAGRANT_NAMES_ARRAY[$INDEX]}
}

function cache_proxy_random_vagrant () {
    local INDEX=$((RANDOM%TARGET_VM_COUNT))
    cache_proxy_nth_vagrant $INDEX
}

function cache_proxy_nth_host () {
    local INDEX=$1
    local CACHE_PROXY_HOST_PORT=${CACHE_PROXY_IPS_ARRAY[$INDEX]}
    CACHE_PROXY_HOST=$(echo $CACHE_PROXY_HOST_PORT|awk 'BEGIN {FS=":"};{print $1}')
}

function cache_proxy_random_host () {
    local INDEX=$((RANDOM%TARGET_VM_COUNT))
    cache_proxy_nth_host $INDEX
}

function cache_proxy_cli () {
    local INDEX="$1"
    if [[ $INDEX -lt 0 || "$INDEX" -ge $TARGET_VM_COUNT ]]; then
        >&2 echo "cache_proxy_cli index out of bounds, $INDEX is not within the range [0..${TARGET_VM_COUNT})"
        CACHE_PROXY_RESPONSE=""
        return
    fi
    shift
    local CACHE_PROXY_COMMAND="$@"
    if [[ "$REDIS_CLI" == "" ]]; then
        cache_proxy_nth_vagrant $INDEX
        CACHE_PROXY_RESPONSE=$(vagrant ssh $CACHE_PROXY_VAGRANT -c "$BDP_PRIV/redis/bin/redis-cli -p $CACHE_PROXY_PORT $CACHE_PROXY_COMMAND" 2>/dev/null)
    else
        cache_proxy_nth_host $INDEX
        CACHE_PROXY_RESPONSE=$($REDIS_CLI -h $CACHE_PROXY_HOST -p $CACHE_PROXY_PORT $CACHE_PROXY_COMMAND)
    fi
}

function cache_proxy_get () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    cache_proxy_cli $INDEX get $BUCKET_KEY
    CACHE_PROXY_VALUE="$CACHE_PROXY_RESPONSE"
}

function cache_proxy_put () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL=${3:-""}
    cache_proxy_cli $INDEX set $BUCKET_KEY $TTL
}

function cache_proxy_delete () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    cache_proxy_cli $INDEX del $BUCKET_KEY
}

function cache_proxy_pexpire () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL="$3"
    cache_proxy_cli $INDEX pexpire $BUCKET_KEY $TTL
}

function cache_proxy_expire () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL="$3"
    cache_proxy_cli $INDEX expire $BUCKET_KEY $TTL
}

