#! /bin/bash
BUCKET=$1
KEY=$2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_riak_client.sh"

riak_delete "$BUCKET" "$KEY"
