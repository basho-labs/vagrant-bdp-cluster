# Basho Data Platform (BDP) Vagrant Cluster
This is a Vagrant project using shell provisioning to bring up a cluster of
TARGET_VM_COUNT Riak nodes, ready to manage services using the BDP.

BDP services include:
 * Riak        - Persistent data store
 * Spark       - Data analysis
 * Redis       - Cache store
 * Cache-Proxy - Cache strategy

## Configuration
Install Vagrant ( http://downloads.vagrantup.com/ )

## Clone repository
```bash
$ git clone git@github.com:paegun/vagrant-bdp-cluster.git
$ cd vagrant-bdp-cluster
```

## Set Environment
```bash
$ cp env-example.sh env.sh
```
Within env.sh, set values accordingly. The example provides meaning for each.
Since the download urls are not public, env.sh is intentionally not shared.
```bash
$ . env.sh
```

## Download BDP
```bash
$ ./bin/download.sh
```

## Provision
```bash
$ vagrant up
```
Post-provisioning, either follow the Quickstart path or perform the quickstart
steps one-by-one, starting at Create Riak Cluster.

## Quickstart
```bash
$ ./bin/quickstart.sh
```
The steps of the Quickstart are broken out here. Feel free to skip ahead to
Test BDP Services.

## Create Riak Cluster
```bash
$ ./bin/riak_cluster_create.sh
```

## Verify Riak Cluster
```bash
$ ./bin/riak_test.sh
```

## Create BDP Cluster
```bash
$ ./bin/bdp_cluster_create.sh
```

## Verify BDP Cluster
```bash
$ ./bin/bdp_service_status.sh
```
The BDP Service Status should list no running servies and no available services.

## Register BDP Service Configs
```bash
$ ./bin/redis_service_config_create.sh
$ ./bin/cache_proxy_service_config_create.sh
$ ./bin/spark_worker_service_config_create.sh
$ ./bin/spark_master_service_config_create.sh
```

## Verify BDP Service Configs
```bash
$ ./bin/bdp_service_status.sh
```
The BDP Service Status should list no running services and within the available
services, the following:

```
+---------------+------------+
|    Service    |    Type    |
+---------------+------------+
|my-cache-proxy |cache-proxy |
|   my-redis    |   redis    |
|my-spark-master|spark-master|
|my-spark-worker|spark-worker|
+---------------+------------+
```

## Prepare Riak for Spark Integrations
```bash
$ ./bin/spark_riak_bucket_create.sh
```

## Start BDP Services
```bash
$ ./bin/bdp_service_control.sh start my-cache-group my-redis
$ ./bin/bdp_service_control.sh start my-cache-group my-cache-proxy
$ ./bin/bdp_service_control.sh start my-analysis-group my-spark-master
$ ./bin/bdp_service_control.sh start my-analysis-group my-spark-worker
```

## Verify BDP Services Started
```bash
$ ./bin/bdp_service_status.sh
$ ./bin/bdp_service_control.sh get-pid my-cache-group my-redis
$ ./bin/bdp_service_control.sh get-pid my-cache-group my-cache-proxy
$ ./bin/bdp_service_control.sh get-pid my-cache-group my-spark-master
$ ./bin/bdp_service_control.sh get-pid my-cache-group my-spark-worker
```
The BDP Service Status should list running services including the following:

```
+--------------+---------------+-----------------------+
|    Group     |    Service    |         Node          |
+--------------+---------------+-----------------------+
|my-cache-group|my-cache-proxy |riak_bdp_1@192.168.50.2|
|my-cache-group|my-cache-proxy |riak_bdp_2@192.168.50.3|
|my-cache-group|my-cache-proxy |riak_bdp_3@192.168.50.4|
|my-cache-group|   my-redis    |riak_bdp_1@192.168.50.2|
|my-cache-group|   my-redis    |riak_bdp_2@192.168.50.3|
|my-cache-group|   my-redis    |riak_bdp_3@192.168.50.4|
|my-spark-group|my-spark-master|riak_bdp_1@192.168.50.2|
|my-spark-group|my-spark-master|riak_bdp_2@192.168.50.3|
|my-spark-group|my-spark-master|riak_bdp_3@192.168.50.4|
+--------------+---------------+-----------------------+
```

and within the available services, the following:

```
+---------------+------------+
|    Service    |    Type    |
+---------------+------------+
|my-cache-proxy |cache-proxy |
|   my-redis    |   redis    |
|my-spark-master|spark-master|
|my-spark-worker|spark-worker|
+---------------+------------+
```

BDP Service Control get-pid yields the following:

```
riak1 18303
riak2 16642
riak3 16665
```

If any of the services local process identifiers (pid) is empty, restart
the specific service as follows (using spark-worker as an example):

```bash
./bin/bdp_service_control.sh stop my-cache-group my-spark-worker
./bin/bdp_service_control.sh start my-cache-group my-spark-worker
./bin/bdp_service_control.sh get-pid my-cache-group my-spark-worker
```

## Test BDP Services
Test each BDP service by following its quick start guide and/or examples.
Refer to bin/riak_test.sh for how to encapsulate test commands to be executed
across all nodes.

## Keep up to date
This Vagrant solution was developed and tested against the BDP beta release cut
on 2015-07-15.

As BDP is being developed, you may need to update your local Vagrant setup via
git pull.  If the Vagrant setup is out-of-date, it is highly suggested to
update BDP download urls, destroy the existing vagrants, vagrant up, and
apply the quickstart script.

## Support and Contributions
**This tool is provided without support.** Definitely do not ever use this in
production, it's strictlya development tool.

If you'd like to contribute, fork and make a pull request.

Thanks!
