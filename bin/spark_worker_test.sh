#! /bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/spark_worker_submit.sh 1 examples/src/main/python/pi.py 3
echo "Successfully tested Spark worker"
