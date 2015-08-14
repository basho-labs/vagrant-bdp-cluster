#! /bin/bash
INDEX=$1
SOURCE_FILE=$2
shift 2
ARGS=$@

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/include_spark_worker_client.sh"

spark_worker_submit "$INDEX" "$SOURCE_FILE" $ARGS
EXIT_CODE=$?
echo -e "$SPARK_WORKER_RESPONSE"
exit $EXIT_CODE
