#! /bin/bash
INDEX=$1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_redis_client.sh"

redis_cli $INDEX info
echo -e "$REDIS_RESPONSE"
