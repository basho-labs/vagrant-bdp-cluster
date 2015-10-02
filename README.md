# Basho Data Platform (BDP) Vagrant Cluster
This is a Vagrant project using shell provisioning to bring up a cluster of
TARGET_VM_COUNT Riak nodes, ready to manage services using the BDP.

Basho Data Platform (BDP) is not yet public.  More information regarding BDP is
available, see http://basho.com/basho-data-platform/ .  The remainder of this
setup assumes that you have been provided download links as part of an
early access evaluation.

BDP services include:
 * Riak        - Persistent data store
 * Spark       - Data analysis
 * Redis       - Cache store
 * Cache-Proxy - Cache strategy

## Configuration
Install Vagrant ( http://downloads.vagrantup.com/ )
[Optional] Install parallel, otherwise installed via bin/provision.sh

## Clone repository
```bash
$ git clone git@github.com:basho-labs/vagrant-bdp-cluster.git
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
To expedite provisioning, GNU parallel is used to parallelize the provisioning
step of the vagrant up.
```bash
$ ./bin/provision.sh
```

With parallel provisioning, provisioning and quickstarting a 3 node cluster
on an i7 (4 cores, 2.8 Ghz, 16 GB RAM) machine  was tested to complete in:
provisioning - 2m23.430s
quickstart   - 2m51.062s

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

```bash
./bin/smoke_test.sh
```

The smoke test tests each service with a minimal test that assures expected
functionality.

## Keep up to date
This Vagrant solution was developed and tested against the BDP 1.0 EE and OSS versions.

As BDP is being developed, you may need to update your local Vagrant setup via
git pull.  If the Vagrant setup is out-of-date, it is highly suggested to
update BDP download urls, destroy the existing vagrants, vagrant up, and
apply the quickstart script.

## Support and Contributions
**This tool is provided without support.** Definitely do not ever use this in
production, it's strictly a development tool.

If you'd like to contribute, fork and make a pull request.

Thanks!
