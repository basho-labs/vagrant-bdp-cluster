#! /bin/bash
INDEX=$1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_redis_client.sh"

if [[ "$REDIS_CLI" == "" ]]; then
    "redis monitor requires redis-cli locally installed"
    exit 1
fi
redis_nth_host "$INDEX"
$REDIS_CLI -h $REDIS_HOST -p $REDIS_PORT monitor
