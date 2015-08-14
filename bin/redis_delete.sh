#! /bin/bash
INDEX=$1
BUCKET=$2
KEY=$3

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_redis_client.sh"

redis_delete "$INDEX" "$BUCKET:$KEY"
