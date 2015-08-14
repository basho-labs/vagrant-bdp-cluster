#! /bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/riak_test.sh \
&& $DIR/cache_proxy_test.sh \
&& $DIR/spark_worker_test.sh \
&& echo "Successfully tested the critical features of BDP"
