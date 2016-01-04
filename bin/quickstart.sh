#! /bin/bash
RETRY_DELAY=1

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
    local TARGET_VAGRANT_NAME=$3
    if [[ "$TARGET_VAGRANT_NAME" == "" ]]; then
        let EXPECTED_STATUS_LINES=$TARGET_VM_COUNT+1
    else
        let EXPECTED_STATUS_LINES=1+1
    fi
    local RETRIES=60
    while [[ $RETRIES > 0 ]]; do
        ./bin/bdp_service_control.sh start "$SERVICE_GROUP" "$SERVICE_CONFIG" "$TARGET_VAGRANT_NAME" >bdp_service_start.log 2>&1
        # assert_exit "starting $SERVICE_CONFIG"
        # STATUS_LINES=$(./bin/bdp_service_status.sh |grep "$SERVICE_CONFIG" |wc -l)
        # if [[ "$STATUS_LINES" -ge "$EXPECTED_STATUS_LINES" ]]; then
        if [ $? != 0 ]; then
            if [ grep 'already started' bdp_service_start.log ]; then
                RETRIES=0
            else
                let RETRIES-=1
            fi
        else
            RETRIES=0
        fi
    done
    cat bdp_service_start.log
    rm bdp_service_start.log
}

echo "enable ensemble on ~head node"
./bin/riak_enable_ensemble.sh

echo "create the bdp cluster"
RETRIES=60
while [[ $RETRIES > 0 ]]; do
    OUTPUT=$(./bin/bdp_cluster_create.sh)
    if [[ $OUTPUT =~ "Node joined" ]]; then
        EXIT_CODE=0
        RETRIES=0
        echo ""
    else
        EXIT_CODE=1
        let RETRIES-=1
        printf "."
        sleep $RETRY_DELAY
    fi
done
if [[ $EXIT_CODE != 0 ]]; then
    (exit $EXIT_CODE)
fi
assert_exit "create bdp cluster"

echo "create the riak cluster"
./bin/riak_cluster_create.sh
assert_exit "create riak cluster"
RETRIES=120
while [[ $RETRIES > 0 ]]; do
    root_ensemble=$(./bin/riak_control.sh ensemble-status |grep "root")
    if [[ $root_ensemble =~ 'riak' ]]; then
        RETRIES=0
        echo ""
    else
        let RETRIES-=1
        printf "."
        sleep $RETRY_DELAY
    fi
done

echo "test the riak cluster"
./bin/riak_test.sh
assert_exit "test riak cluster"

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
        sleep $RETRY_DELAY
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
            sleep $RETRY_DELAY
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
if [[ "$OSS" -eq 1 ]]; then
    retry_bdp_service_start "my-analysis-group" "my-spark-master" "riak1"
else
    retry_bdp_service_start "my-analysis-group" "my-spark-master"
fi
retry_bdp_service_start "my-cache-group" "my-redis"
retry_bdp_service_start "my-cache-group" "my-cache-proxy"
./bin/bdp_service_control.sh stop "my-cache-group" "my-cache-proxy"
retry_bdp_service_start "my-cache-group" "my-cache-proxy"
retry_bdp_service_start "my-analysis-group" "my-spark-worker"
echo "verify bdp services were started"
./bin/bdp_service_status.sh
assert_exit "verify bdp cluster, likely insufficient up nodes"
echo "verify bdp services have local process identifiers (pids)"
./bin/bdp_service_control.sh get-pid my-cache-group my-redis
assert_exit "getting the pids for my-redis"
./bin/bdp_service_control.sh get-pid my-cache-group my-cache-proxy
assert_exit "getting the pids for my-cache-proxy"
if [[ "$OSS" -eq 1 ]]; then
    ./bin/bdp_service_control.sh get-pid my-cache-group my-spark-master "riak1"
    assert_exit "getting the pids for my-spark-master"
else
    ./bin/bdp_service_control.sh get-pid my-cache-group my-spark-master
    assert_exit "getting the pids for my-spark-master"
fi
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-worker
assert_exit "getting the pids for my-spark-worker"
echo "verifying BDP functionality (smoke test)"
./bin/smoke_test.sh
assert_exit "smoke test failed, verify the configuration and logs for the failing service"
