#! /bin/bash
function assert_exit () {
    local EXIT_CODE=$?
    local MESSAGE=$1
    if [[ $EXIT_CODE != 0 ]]; then
        echo "[$EXIT_CODE]: Failed to $MESSAGE"
        exit $EXIT_CODE
    fi
}

echo "create the riak cluster"
./bin/riak_cluster_create.sh
assert_exit "create riak cluster"
echo "test the riak cluster"
./bin/riak_test.sh
assert_exit "test riak cluster"
echo "create the bdp cluster"
./bin/bdp_cluster_create.sh
assert_exit "create bdp cluster"
echo "verify the bdp cluster is established"
./bin/bdp_service_status.sh
assert_exit "verify bdp cluster, likely insufficient up nodes"
echo "create bdp core service configurations"
for i in `ls bin_service_config_create.sh`;do
    .$i
    assert_exit "creating service config $i"
done
echo "verify bdp service configurations were created"
./bin/bdp_service_status.sh
assert_exit "verify bdp cluster, likely insufficient up nodes"
echo "setting up bucket properties for spark"
./bin/spark_riak_bucket_create.sh
assert_exit "setting bucket properties for spark"
echo "starting my-redis, my-cache-proxy, my-spark-master and my-spark-worker"
./bin/bdp_service_control.sh start my-cache-group my-redis
assert_exit "starting my-redis"
./bin/bdp_service_control.sh start my-cache-group my-cache-proxy
assert_exit "starting my-cache-proxy"
./bin/bdp_service_control.sh start my-analysis-group my-spark-master
assert_exit "starting my-spark-master"
./bin/bdp_service_control.sh start my-analysis-group my-spark-worker
assert_exit "starting my-spark-worker"
echo "verify bdp services were started"
./bin/bdp_service_status.sh
assert_exit "verify bdp cluster, likely insufficient up nodes"
echo "verify bdp services have local process identifiers (pids)"
./bin/bdp_service_control.sh get-pid my-cache-group my-redis
assert_exit "getting the pids for my-redis"
./bin/bdp_service_control.sh get-pid my-cache-group my-cache-proxy
assert_exit "getting the pids for my-cache-proxy"
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-master
assert_exit "getting the pids for my-spark-master"
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-worker
assert_exit "getting the pids for my-spark-worker"

