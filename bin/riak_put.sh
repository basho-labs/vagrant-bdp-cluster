#! /bin/bash
BUCKET=$1
KEY=$2
VALUE=$3

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_riak_client.sh"

riak_put "$BUCKET" "$KEY" "$VALUE"
exit $?
