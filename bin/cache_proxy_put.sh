#! /bin/bash
INDEX=$1
BUCKET=$2
KEY=$3
VALUE=$4

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_cache_proxy_client.sh"

cache_proxy_put "$INDEX" "$BUCKET:$KEY" "$VALUE"
