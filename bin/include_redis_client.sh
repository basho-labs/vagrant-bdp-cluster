#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cluster.sh"

redis_port
vagrant_names $TARGET_VM_COUNT
vagrant_ips $TARGET_VM_COUNT $REDIS_PORT
VAGRANT_NAMES_ARRAY=($VAGRANT_NAMES)
REDIS_IPS_ARRAY=($VAGRANT_IPS)

REDIS_CLI=${REDIS_CLI:-"$(which redis-cli)"}

function redis_nth_vagrant () {
    local INDEX=$1
    REDIS_VAGRANT=${VAGRANT_NAMES_ARRAY[$INDEX]}
}

function redis_random_vagrant () {
    local INDEX=$((RANDOM%TARGET_VM_COUNT))
    redis_nth_vagrant $INDEX
}

function redis_nth_host () {
    local INDEX=$1
    local REDIS_HOST_PORT=${REDIS_IPS_ARRAY[$INDEX]}
    REDIS_HOST=$(echo $REDIS_HOST_PORT|awk 'BEGIN {FS=":"};{print $1}')
}

function redis_random_host () {
    local INDEX=$((RANDOM%TARGET_VM_COUNT))
    redis_nth_host $INDEX
}

function redis_cli () {
    local INDEX="$1"
    if [[ "$INDEX" == "" || $INDEX -lt 0 || "$INDEX" -ge $TARGET_VM_COUNT ]]; then
        >&2 echo "redis_cli index out of bounds, $INDEX is not within the range [0..${TARGET_VM_COUNT})"
        REDIS_RESPONSE=""
        return
    fi
    shift
    local REDIS_COMMAND="$@"
    if [[ "$REDIS_CLI" == "" ]]; then
        redis_nth_vagrant $INDEX
        REDIS_RESPONSE=$(vagrant ssh $REDIS_VAGRANT -c "$BDP_PRIV/redis/bin/redis-cli -p $REDIS_PORT $REDIS_COMMAND" 2>/dev/null)
    else
        redis_nth_host $INDEX
        REDIS_RESPONSE=$($REDIS_CLI -h $REDIS_HOST -p $REDIS_PORT $REDIS_COMMAND)
    fi
}

function redis_get () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    redis_cli $INDEX get $BUCKET_KEY
    REDIS_VALUE="$REDIS_RESPONSE"
}

function redis_spanning_get () {
    local BUCKET_KEY="$1"
    local INDEX=""
    REDIS_VALUES=""
    for i in `seq 1 $TARGET_VM_COUNT`; do
        let INDEX=$i-1
        redis_cli $INDEX get $BUCKET_KEY
        REDIS_VALUE="$REDIS_RESPONSE"
        REDIS_VALUES="$REDIS_VALUES$INDEX:\n$REDIS_VALUE\n"
    done
}

function redis_put () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL=${3:-""}
    redis_cli $INDEX set $BUCKET_KEY $TTL
}

function redis_delete () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    redis_cli $INDEX del $BUCKET_KEY
}

function redis_pexpire () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL="$3"
    redis_cli $INDEX pexpire $BUCKET_KEY $TTL
}

function redis_expire () {
    local INDEX="$1"
    local BUCKET_KEY="$2"
    local TTL="$3"
    redis_cli $INDEX expire $BUCKET_KEY $TTL
}

