#! /bin/bash
echo "create the riak cluster"
./bin/riak_cluster_create.sh
echo "test the riak cluster"
./bin/riak_test.sh
echo "create the bdp cluster"
./bin/bdp_cluster_create.sh
echo "verify the bdp cluster is established"
./bin/bdp_service_status.sh
echo "create bdp core service configurations"
for i in `ls bin_service_config_create.sh`;do .$i ;done
echo "verify bdp service configurations were created"
./bin/bdp_service_status.sh
echo "setting up bucket properties for spark"
./bin/spark_riak_bucket_create.sh
echo "starting my-redis, my-cache-proxy, my-spark-master and my-spark-worker"
./bin/bdp_service_control.sh start my-cache-group my-redis
./bin/bdp_service_control.sh start my-cache-group my-cache-proxy
./bin/bdp_service_control.sh start my-analysis-group my-spark-master
./bin/bdp_service_control.sh start my-analysis-group my-spark-worker
echo "verify bdp services were started"
./bin/bdp_service_status.sh
echo "verify bdp services have local process identifiers (pids)"
./bin/bdp_service_control.sh get-pid my-cache-group my-redis
./bin/bdp_service_control.sh get-pid my-cache-group my-cache-proxy
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-master
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-worker

