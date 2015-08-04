# -*- mode: ruby -*-
# vi: set ft=ruby :

# to reduce downloads, vagrants are sharing a sync folder, see bin/download.sh

def usage
<<EOF
usage: TARGET_VM=centos TARGET_VM_COUNT=3 vagrant up

Environment Variables:
TARGET_VM - determines the OS, defaults to 'centos', supports the following:
  centos - Centos 6.5
  ubuntu - Ubuntu 12.04

TARGET_VM_COUNT - determines the number of VM's defaults to 3.

DOWNLOAD_BDP_PACKAGE_CENTOS_FILE - filename containing bdp package for centos
                                   defaults to basho-data-platform-CENTOS.rpm
DOWNLOAD_BDP_EXTRAS_CENTOS_FILE - filename containing bdp extras for centos
                                  defaults to basho-data-platform-extras-CENTOS.rpm
DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE - filename containing bdp package for ubuntu
                                   defaults to basho-data-platform-UBUNTU.deb
DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE - filename containing bdp extras for ubuntu
                                  defaults to basho-data-platform-extras-UBUNTU.deb
EOF
end

def set_default_environment
  ENV['TARGET_VM'] ||= 'centos'
  ENV['TARGET_VM_VARIANT'] ||= '7'
  ENV['TARGET_VM_COUNT'] ||= '3'
  ENV['DOWNLOAD_JAVA_FILE'] ||= 'jdk-8.rpm'
  ENV['DOWNLOAD_BDP_PACKAGE_CENTOS_FILE'] ||= "basho-data-platform-CENTOS.rpm"
  ENV['DOWNLOAD_BDP_EXTRAS_CENTOS_FILE'] ||= "basho-data-platform-extras-CENTOS.rpm"
  ENV['DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE'] ||= "basho-data-platform-UBUNTU.deb"
  ENV['DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE'] ||= "basho-data-platform-extras-UBUNTU.deb"
end
set_default_environment

$target_vm_count = ENV['TARGET_VM_COUNT'].to_i
$target_vm = ENV['TARGET_VM']
$target_vm_variant = ENV['TARGET_VM_VARIANT']
if $target_vm == 'centos'
  if $target_vm_variant == '7'
    $vm_box = 'chef/centos-7.0'
  else
    $vm_box = 'chef/centos-6.5'
  end
elsif $target_vm == 'ubuntu'
  $vm_box = 'chef/ubuntu-12.04'
else
  raise usage
  exit 1
end

def provisioning_script(opts = {})
  if $target_vm == 'centos'
    provisioning_script_centos(opts)
  elsif $target_vm == 'ubuntu'
    provisioning_script_ubuntu(opts)
  else
    raise usage
  end
end

def provisioning_script_centos(opts = {})
  node_number = opts[:node_number] || 1
  ip_address = opts[:ip_address] || '127.0.0.1'
  bdp_path = '/usr/lib64/riak/lib/data_platform-1'
  download_java_file = ENV['DOWNLOAD_JAVA_FILE']
  download_bdp_package_file = ENV['DOWNLOAD_BDP_PACKAGE_CENTOS_FILE']
  download_bdp_extras_file = ENV['DOWNLOAD_BDP_EXTRAS_CENTOS_FILE']

<<EOF
DIR=$PWD
# increase open file limit
if [[ $(sysctl fs.file-max |grep 65536) == "" ]]; then
  sudo sysctl fs.file-max=65536
  sudo sysctl -p
  # ulimit -n support for CentOS
  sudo bash -c "cat <<EOF_LIMITS >> /etc/security/limits.conf
*                soft    nofile          65536
*                hard    nofile          65536
EOF_LIMITS
"

fi
# install jdk 8
if [[ $(which javac) == "" ]]; then
  echo "installing jdk 8"
  sudo yum -y localinstall "$DIR/downloads/#{download_java_file}"
  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
  grep JAVA_HOME /etc/environment >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/environment"
  echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"
fi
# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp beta 1"
  cd $DIR/downloads
  sudo yum -y --nogpgcheck --noplugins localinstall "#{download_bdp_package_file}"
  if [[ -d basho-data-platform-extras-CENTOS ]]; then
    cd basho-data-platform-extras-CENTOS
    sudo ./install.sh
  else
    sudo rpm --replacefiles -i "#{download_bdp_extras_file}"
    if [[ ! -d "#{bdp_path}/priv/spark-master/logs/" ]]; then
      sudo mkdir "#{bdp_path}/priv/spark-master/logs"
      sudo chown riak:riak "#{bdp_path}/priv/spark-master/logs"
      sudo mkdir "#{bdp_path}/priv/spark-worker/logs"
      sudo chown riak:riak "#{bdp_path}/priv/spark-worker/logs"
      sudo mkdir "#{bdp_path}/priv/spark-worker/work"
      sudo chown riak:riak "#{bdp_path}/priv/spark-worker/work"
    fi 
  fi
  cd $DIR

  # configure spark master
  echo "configuring spark-master"
  sudo bash -c "echo 'SPARK_MASTER_IP=#{ip_address} >> #{bdp_path}/priv/spark-master/conf/spark-env.sh'"

  # configure riak
  echo "configuring riak"
  sudo sed --in-place=bak 's/distributed_cookie = .*/distributed_cookie = riak_bdp/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/nodename = .*/nodename = riak_bdp_#{node_number}@#{ip_address}/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.http.internal = .*/listener.http.internal = 0.0.0.0:8098/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = 0.0.0.0:8087/' /etc/riak/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'handoff.ip = 0.0.0.0' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> /etc/riak/riak.conf"

  echo "restarting Riak"
  sudo service riak stop
  sudo service riak start

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi
EOF
  # NOTE: joining the cluster must be done after provisioning all boxes, so use bin/create_riak_cluster.sh
end

def provisioning_script_ubuntu(opts = {})
  node_number = opts[:node_number] || 1
  ip_address = opts[:ip_address] || '127.0.0.1'
  bdp_path = '/usr/lib/riak/lib/data_platform-1'
  download_bdp_package_file = ENV['DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE']
  download_bdp_extras_file = ENV['DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE']

<<EOF
DIR=$PWD
# increase open file limit
if [[ $(sysctl fs.file-max |grep 65536) == "" ]]; then
  sudo bash -c "cat <<EOF_LIMITS >> /etc/security/limits.conf
*                soft    nofile          65536
*                hard    nofile          65536
EOF_LIMITS
"
fi

# install jdk 8
if [[ $(which javac) == "" ]]; then
  echo "installing jdk 8"
  # properties packages are for add-apt-repository
  # debconf-utils is to accept the java license
  sudo apt-get install -y software-properties-common python-software-properties debconf-utils
  sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get update
  # accept java license
  sudo echo -e oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
  sudo apt-get install -y oracle-java8-installer >/dev/null 2>&1
  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
  grep JAVA_HOME /etc/environment >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/environment"
  echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"
fi

# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp beta 1"
  cd $DIR/downloads
  sudo dpkg -i "#{download_bdp_package_file}"
  if [[ -d basho-data-platform-extras-UBUNTU ]]; then
    cd basho-data-platform-extras-UBUNTU
    sudo ./install.sh
  else
    sudo dpkg -i --force-overwrite "#{download_bdp_extras_file}"
    if [[ ! -d "#{bdp_path}/priv/spark-master/logs/" ]]; then
      sudo mkdir "#{bdp_path}/priv/spark-master/logs"
      sudo chown riak:riak "#{bdp_path}/priv/spark-master/logs"
      sudo mkdir "#{bdp_path}/priv/spark-worker/logs"
      sudo chown riak:riak "#{bdp_path}/priv/spark-worker/logs"
      sudo mkdir "#{bdp_path}/priv/spark-worker/work"
      sudo chown riak:riak "#{bdp_path}/priv/spark-worker/work"
    fi
  fi
  cd $DIR

  # configure spark master
  echo "configuring spark-master"
  sudo bash -c "echo 'SPARK_MASTER_IP=#{ip_address} >> #{bdp_path}/priv/spark-master/conf/spark-env.sh'"

  # configure riak
  echo "configuring riak"
  sudo sed --in-place=bak 's/distributed_cookie = .*/distributed_cookie = riak_bdp/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/nodename = .*/nodename = riak_bdp_#{node_number}@#{ip_address}/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.http.internal = .*/listener.http.internal = 0.0.0.0:8098/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = 0.0.0.0:8087/' /etc/riak/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'handoff.ip = 0.0.0.0' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> /etc/riak/riak.conf"

  echo "restarting Riak"
  sudo service riak stop
  sudo service riak start

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi
EOF
  # NOTE: joining the cluster must be done after provisioning all boxes, so use bin/create_riak_cluster.sh
end

Vagrant.configure(2) do |config|
  (1..$target_vm_count).each do |node_number|
    opts = {
     node_number: node_number,
     node_name: "riak#{node_number}",
     ip_address: "192.168.50.#{node_number + 1}"
    }
    primary = (opts[:node_number] == 1)
    config.vm.define opts[:node_name], primary: primary do |n|
      n.vm.box = $vm_box

      n.vm.synced_folder "downloads/", "/home/vagrant/downloads"

      n.vm.network "private_network", ip: opts[:ip_address]

      # limit memory consumption
      n.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
      end

      # port forwards
      # handoff
      n.vm.network "forwarded_port", guest: 8099, host: "5#{opts[:node_number]}099".to_i, auto_correct: true
      # http
      n.vm.network "forwarded_port", guest: 8098, host: "5#{opts[:node_number]}098".to_i, auto_correct: true
      # pb
      n.vm.network "forwarded_port", guest: 8087, host: "5#{opts[:node_number]}087".to_i, auto_correct: true

      # ssh port forwards
      n.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", disabled: true
      n.vm.network "forwarded_port", guest: 22, host: "5#{opts[:node_number]}088".to_i, auto_correct: true

      n.vm.provision "shell", inline: provisioning_script(opts)
    end
  end
end

