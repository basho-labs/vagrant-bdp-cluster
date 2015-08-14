#! /bin/bash
function assert_exit () {
    local EXIT_CODE=$?
    local MESSAGE=$1
    if [[ $EXIT_CODE != 0 ]]; then
        echo "[$EXIT_CODE]: Failed to $MESSAGE"
        exit $EXIT_CODE
    fi
}
function retry_bdp_service_start() {
    local SERVICE_GROUP=$1
    local SERVICE_CONFIG=$2
    let EXPECTED_STATUS_LINES=$TARGET_VM_COUNT+1
    local RETRIES=3
    while [[ $RETRIES > 0 ]]; do
        ./bin/bdp_service_control.sh start "$SERVICE_GROUP" "$SERVICE_CONFIG" >bdp_service_start.log 2>&1
        assert_exit "starting $SERVICE_CONFIG"
        STATUS_LINES=$(./bin/bdp_service_status.sh |grep "$SERVICE_CONFIG" |wc -l)
        if [[ "$STATUS_LINES" -ge "$EXPECTED_STATUS_LINES" ]]; then
            RETRIES=0
        fi
    done
    cat bdp_service_start.log
    rm bdp_service_start.log
}

echo "create the riak cluster"
./bin/riak_cluster_create.sh
assert_exit "create riak cluster"
echo "test the riak cluster"
./bin/riak_test.sh
assert_exit "test riak cluster"

echo "create the bdp cluster"
RETRIES=60
while [[ $RETRIES > 0 ]]; do
    OUTPUT=$(./bin/bdp_cluster_create.sh)
    EXIT_CODE=$?
    if [[ $OUTPUT =~ "Node joined" ]]; then
        let RETRIES-=1
        printf "."
        sleep 1
    else
        RETRIES=0
        echo ""
    fi
done
if [[ $EXIT_CODE != 0 ]]; then
    (exit $EXIT_CODE)
fi
assert_exit "create bdp cluster"

echo "verify the bdp cluster is established"
RETRIES=60 #<< experiencing 25-30s periods of 
while [[ $RETRIES > 0 ]]; do
    # NOTE: intentionally freshly logging output to only emit the last run below
    ./bin/bdp_service_status.sh >bdp_service_status.log 2>&1
    EXIT_CODE=$?
    if [[ $EXIT_CODE == 0 ]]; then
        RETRIES=0
        echo ""
    else
        let RETRIES-=1
        printf "."
        sleep 1
    fi
done
cat bdp_service_status.log
rm bdp_service_status.log
if [[ $EXIT_CODE != 0 ]]; then
    (exit $EXIT_CODE)
    assert_exit "verify bdp cluster, likely insufficient up nodes"
fi

echo "create bdp core service configurations"
for i in `ls bin/*service_config_create.sh`;do
    RETRIES=60
    EXIT_CODE=0
    while [[ $RETRIES > 0 ]]; do
        OUTPUT=$(./$i)
        EXIT_CODE=$?
        if [[ $OUTPUT =~ 'failed!' ]]; then
            let RETRIES-=1
            printf "."
            sleep 1
        else
            RETRIES=0
            echo ""
        fi
    done
    $(exit $EXIT_CODE)
    assert_exit "creating service config $i"
done
echo "verify bdp service configurations were created"
./bin/bdp_service_status.sh
assert_exit "verify bdp cluster, likely insufficient up nodes"
echo "setting up bucket properties for spark"
./bin/spark_riak_bucket_create.sh
assert_exit "setting bucket properties for spark"
echo "starting my-redis, my-cache-proxy, my-spark-master and my-spark-worker"
retry_bdp_service_start "my-cache-group" "my-redis"
retry_bdp_service_start "my-cache-group" "my-cache-proxy"
retry_bdp_service_start "my-analysis-group" "my-spark-master"
retry_bdp_service_start "my-analysis-group" "my-spark-worker"
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
echo "verifying BDP functionality (smoke test)"
./bin/smoke_test.sh
