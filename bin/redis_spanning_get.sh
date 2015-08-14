#! /bin/bash
BUCKET=$1
KEY=$2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_redis_client.sh"

redis_spanning_get "$BUCKET:$KEY"
echo -e "$REDIS_VALUES"
