# -*- mode: ruby -*-
# vi: set ft=ruby :

# to reduce downloads, vagrants are sharing a sync folder, see bin/download.sh

def usage
<<EOF
usage: TARGET_VM=centos TARGET_VM_COUNT=3 vagrant up

Environment Variables:
TARGET_VM - determines the OS, defaults to 'centos'
TARGET_VM_VARIANT - determines the OS variant, supports the following (quoted):
  centos - CentOS 6.5 "6"
           CentOS 7.0 "7"
  ubuntu - Ubuntu 12.04 "precise"
           Ubuntu 14.04 "trusty"
  debian - Debian 7.8 "wheezy"
           Debian 8.0 "jessie"
  osx    - OSX 10.10 "yosemite"

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
  ENV['OSS'] ||= '0'
  ENV['TARGET_VM'] ||= 'centos'
  ENV['TARGET_VM_VARIANT'] ||= '7'
  ENV['TARGET_VM_COUNT'] ||= '3'
  ENV['DOWNLOAD_JAVA_FILE'] ||= 'jdk-8.rpm'
  ENV['DOWNLOAD_BDP_PACKAGE_CENTOS_FILE'] ||= "basho-data-platform-CENTOS.rpm"
  ENV['DOWNLOAD_BDP_EXTRAS_CENTOS_FILE'] ||= "basho-data-platform-extras-CENTOS.rpm"
  ENV['DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE'] ||= "basho-data-platform-UBUNTU.deb"
  ENV['DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE'] ||= "basho-data-platform-extras-UBUNTU.deb"
  ENV['DOWNLOAD_BDP_PACKAGE_DEBIAN_FILE'] ||= "basho-data-platform-DEBIAN.deb"
  ENV['DOWNLOAD_BDP_EXTRAS_DEBIAN_FILE'] ||= "basho-data-platform-extras-DEBIAN.deb"
  ENV['DOWNLOAD_BDP_PACKAGE_OSX_FILE'] ||= "basho-data-platform-OSX.tar.gz"
  ENV['DOWNLOAD_BDP_EXTRAS_OSX_FILE'] ||= "basho-data-platform-extras-OSX.pkg"
end
set_default_environment

$oss = ENV['OSS'].to_i
$target_vm_count = ENV['TARGET_VM_COUNT'].to_i
$target_vm = ENV['TARGET_VM']
$target_vm_variant = ENV['TARGET_VM_VARIANT']
if $target_vm == 'centos'
  if $target_vm_variant == '7'
    $vm_box = 'bento/centos-7.1'
  else
    $vm_box = 'bento/centos-6.7'
  end
elsif $target_vm == 'ubuntu'
  if $target_vm_variant == 'trusty'
    $vm_box = 'bento/ubuntu-14.04'
  else
    $vm_box = 'bento/ubuntu-12.04'
  end
elsif $target_vm == 'debian'
  if $target_vm_variant == 'jessie'
    $vm_box = 'bento/debian-8.1'
    $target_vm_variant_equivalent = 'trusty'
  else
    $vm_box = 'bento/debian-7.8'
    $target_vm_variant_equivalent = 'precise'
  end
elsif $target_vm == 'osx'
  $vm_box = 'osx-yosemite' #<< added via provision.sh, if needed
else
  raise usage
  exit 1
end

def provisioning_script(opts = {})
  if $target_vm == 'centos'
    provisioning_script_centos(opts)
  elsif $target_vm == 'ubuntu'
    provisioning_script_ubuntu(opts)
  elsif $target_vm == 'debian'
    provisioning_script_debian(opts)
  elsif $target_vm == 'osx'
    provisioning_script_osx(opts)
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

# verify packages are downloaded
if [[ ! -e "$DIR/downloads/#{download_bdp_package_file}" ]]; then
  echo "This vagrant setup requires configuration of download urls, see README.md for further details."
  exit 1
fi

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
  if [[ "$JAVA_HOME" == "" ]]; then
    echo "failed to install jdk 8"
    exit 1
  fi
  grep JAVA_HOME /etc/environment >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/environment"
  echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"
fi

# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp"
  cd $DIR/downloads
  sudo yum -y --nogpgcheck --noplugins localinstall "#{download_bdp_package_file}"
  if [[ -d basho-data-platform-extras-CENTOS ]]; then
    cd basho-data-platform-extras-CENTOS
    sudo ./install.sh
  else
    sudo rpm -i "#{download_bdp_extras_file}"
    if [[ "$?" != "0" ]]; then
        echo "the bdp extras package failed to install"
        exit 1
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
  sudo sed --in-place=bak 's/listener.http.internal = .*/listener.http.internal = #{ip_address}:8098/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = #{ip_address}:8087/' /etc/riak/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'handoff.ip = #{ip_address}' >> /etc/riak/riak.conf"
  if [[ "#{$oss}" -eq 0 ]]; then
    # leader election service is an EE feature
    sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> /etc/riak/riak.conf"
    sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> /etc/riak/riak.conf"
  fi

  echo "restarting Riak"
  sudo service riak stop
  sudo service riak start

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi
EOF
end

def provisioning_script_ubuntu(opts = {})
  node_number = opts[:node_number] || 1
  ip_address = opts[:ip_address] || '127.0.0.1'
  bdp_path = '/usr/lib/riak/lib/data_platform-1'
  download_bdp_package_file = ENV['DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE']
  download_bdp_extras_file = ENV['DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE']

<<EOF
DIR=$PWD
# verify packages are downloaded
if [[ ! -e "$DIR/downloads/#{download_bdp_package_file}" ]]; then
  echo "This vagrant setup requires configuration of download urls, see README.md for further details."
  exit 1
fi

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
  RETRIES=3
  while [[ $RETRIES > 0 ]]; do
    sudo apt-get install -y software-properties-common python-software-properties debconf-utils
    if [[ "$?" == "0" ]]; then
      RETRIES=0
    else
      let RETRIES-=1
      echo "retrying install of software-properties"
      sudo apt-get update
    fi
  done

  echo "" |sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get update
  # accept java license
  sudo echo -e oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
  sudo apt-get install -y oracle-java8-installer >/dev/null 2>&1
  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
  if [[ "$JAVA_HOME" == "" ]]; then
    echo "failed to install jdk 8"
    exit 1
  fi
  grep JAVA_HOME /etc/environment >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/environment"
  echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"
fi

# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp"
  cd $DIR/downloads
  sudo dpkg -i "#{download_bdp_package_file}"
  if [[ -d basho-data-platform-extras-UBUNTU ]]; then
    cd basho-data-platform-extras-UBUNTU
    sudo ./install.sh
  else
    sudo dpkg -i "#{download_bdp_extras_file}"
    if [[ "$?" != "0" ]]; then
        echo "the bdp extras package failed to install"
        exit 1
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
  sudo sed --in-place=bak 's/listener.http.internal = .*/listener.http.internal = #{ip_address}:8098/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = #{ip_address}:8087/' /etc/riak/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'handoff.ip = #{ip_address}' >> /etc/riak/riak.conf"
  if [[ "#{$oss}" -eq 0 ]]; then
    # leader election service is an EE feature
    sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> /etc/riak/riak.conf"
    sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> /etc/riak/riak.conf"
  fi

  echo "restarting Riak"
  sudo service riak stop
  sudo service riak start

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi
EOF
end

def provisioning_script_debian(opts = {})
  node_number = opts[:node_number] || 1
  ip_address = opts[:ip_address] || '127.0.0.1'
  bdp_path = '/usr/lib/riak/lib/data_platform-1'
  download_bdp_package_file = ENV['DOWNLOAD_BDP_PACKAGE_DEBIAN_FILE']
  download_bdp_extras_file = ENV['DOWNLOAD_BDP_EXTRAS_DEBIAN_FILE']

<<EOF
DIR=$PWD
# verify packages are downloaded
if [[ ! -e "$DIR/downloads/#{download_bdp_package_file}" ]]; then
  echo "This vagrant setup requires configuration of download urls, see README.md for further details."
  exit 1
fi

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
  # debconf-utils is to accept the java license
  RETRIES=3
  while [[ $RETRIES > 0 ]]; do
    sudo apt-get install -y debconf-utils
    if [[ "$?" == "0" ]]; then
      RETRIES=0
    else
      let RETRIES-=1
      echo "retrying install of debconf-utils"
      sudo apt-get update
    fi
  done

  if [[ -e "/etc/apt/sources.list.d/webupd8team-java-#{$target_vm_variant}.list" ]]; then
    sudo rm /etc/apt/sources.list.d/webupd8team-java-#{$target_vm_variant}.list
  fi
  sudo bash -c 'echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu #{$target_vm_variant_equivalent} main" | tee /etc/apt/sources.list.d/webupd8team-java.list'
  sudo bash -c 'echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu #{$target_vm_variant_equivalent} main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list'
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
  sudo apt-get update

  # accept java license
  sudo echo -e oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
  sudo apt-get install -y oracle-java8-installer >/dev/null 2>&1
  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
  if [[ "$JAVA_HOME" == "" ]]; then
    echo "failed to install jdk 8"
    exit 1
  fi
  grep JAVA_HOME /etc/environment >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/environment"
  echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"
fi

# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp"
  cd $DIR/downloads
  sudo dpkg -i "#{download_bdp_package_file}"
  if [[ -d basho-data-platform-extras-DEBIAN ]]; then
    cd basho-data-platform-extras-DEBIAN
    sudo ./install.sh
  else
    sudo dpkg -i "#{download_bdp_extras_file}"
    if [[ "$?" != "0" ]]; then
        echo "the bdp extras package failed to install"
        exit 1
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
  sudo sed --in-place=bak 's/listener.http.internal = .*/listener.http.internal = #{ip_address}:8098/' /etc/riak/riak.conf
  sudo sed --in-place=bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = #{ip_address}:8087/' /etc/riak/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> /etc/riak/riak.conf"
  sudo bash -c "echo 'handoff.ip = #{ip_address}' >> /etc/riak/riak.conf"
  if [[ "#{$oss}" -eq 0 ]]; then
    # leader election service is an EE feature
    sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> /etc/riak/riak.conf"
    sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> /etc/riak/riak.conf"
  fi

  echo "restarting Riak"
  sudo service riak stop
  sudo service riak start

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi
EOF
end

def provisioning_script_osx(opts = {})
  node_number = opts[:node_number] || 1
  ip_address = opts[:ip_address] || '127.0.0.1'
  bdp_path = '/usr/lib/riak/lib/data_platform-1'
  download_bdp_package_file = ENV['DOWNLOAD_BDP_PACKAGE_OSX_FILE']
  download_bdp_extras_file = ENV['DOWNLOAD_BDP_EXTRAS_OSX_FILE']

<<EOF
DIR=$PWD
# verify packages are downloaded
if [[ ! -e "$DIR/downloads/#{download_bdp_package_file}" ]]; then
  echo "This vagrant setup requires configuration of download urls, see README.md for further details."
  exit 1
fi

# increase open file limit
for v in kern.maxfilesperproc kern.maxfiles; do
  sudo sed -i bak "s/$v[ ]*=.*//" /etc/sysctl.conf
done
sudo bash -c "grep -v '^$' /etc/sysctl.conf |tee /etc/sysctl.conf"
sudo bash -c "cat <<EOF_LIMITS >> /etc/sysctl.conf
kern.maxfilesperproc=65536
kern.maxfiles=65536
EOF_LIMITS
"
sysctl -w kern.maxfilesperproc=65536
sysctl -w kern.maxfiles=65536
for i in 65536 10240; do
  if ulimit -n $i >/dev/null 2>&1; then
    echo "ulimit -n set to $(ulimit -n)"
    break
  fi
done

sudo bash -c "cat <<EOF_LIMITS > /Library/LaunchDaemons/limit.maxfiles.plist 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxfiles</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxfiles</string>
          <string>65536</string>
          <string>65536</string>
        </array>
      <key>RunAtLoad</key>
        <true/>
      <key>ServiceIPC</key>
        <false/>
    </dict>
  </plist>
EOF_LIMITS
"
sudo bash -c "cat <<EOF_LIMITS > /Library/LaunchDaemons/limit.maxproc.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxproc</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxproc</string>
          <string>2048</string>
          <string>2048</string>
        </array>
      <key>RunAtLoad</key>
        <true />
      <key>ServiceIPC</key>
        <false />
    </dict>
  </plist>
EOF_LIMITS
"
# reload property lists (much faster than a reboot)
for plist in limit.maxfiles limit.maxproc; do
  sudo launchctl unload /Library/LaunchDaemons/$plist.plist
  sudo launchctl load /Library/LaunchDaemons/$plist.plist
done 

sudo bash -c "cat <<EOF_LIMITS >> /etc/profile
ulimit -n 65536
EOF_LIMITS
"
. /etc/profile

# install java
brew update
if brew cask list java |grep 1.8; then
  echo "brew version of java is expected to be 1.8"
  exit 1
else
  brew cask install java
fi
JAVA_HOME=$(dirname $(dirname $(readlink $(which javac))))
if [[ "$JAVA_HOME" == "" ]]; then
  echo "failed to install jdk 8"
  exit 1
fi
grep JAVA_HOME /etc/profile >/dev/null 2>&1 || test $? -ne 0 && sudo bash -c "echo JAVA_HOME=$JAVA_HOME >>/etc/profile"
echo "jdk 8 installed, JAVA_HOME: $JAVA_HOME"

# install bdp
if [[ $(which data-platform-admin) == "" ]]; then
  echo "installing bdp"
  cd $DIR/Downloads
  sudo installer -pkg "#{download_bdp_extras_file}" -target /
  if [[ -d basho-data-platform-OSX ]]; then
    cd basho-data-platform-OSX
    sudo cp -r . "#{bdp_path}"
  else
    sudo installer -pkg "#{download_bdp_package_file}" -target /
    if [[ "$?" != "0" ]]; then
        echo "the bdp core package failed to install"
        exit 1
    fi
  fi
  cd $DIR
  # NOTE: subtle addition of . to PATH to ensure run.sh can be run w/o sourcing
  sudo bash -c "echo 'export PATH=$PATH:#{bdp_path}/bin:.' >>/etc/profile"
  . /etc/profile

  # create riak group and user
  sudo dscl . create /groups/riak
  sudo dscl . append /groups/riak gid $(sudo dscl . list /groups gid |awk 'BEGIN {max = 0};{if ($2 > max) max = $2} END {print max + 1}')
  sudo dscl . -append /groups/riak passwd "*"

  sudo dscl . create /users/riak
  sudo dscl . -append /users/riak uid $(sudo dscl . -list /users uid |awk 'BEGIN {max = 0};{if ($2 > max) max = $2} END {print max + 1}')
sudo dscl . -append /users/riak gid $(sudo dscl . -read /groups/riak gid |awk '{print $2}')
  sudo dscl . -append /users/riak passwd "*"

  # set ownership of BDP directories to the riak user
  sudo chown -R riak:riak #{bdp_path}

  # configure spark master
  echo "configuring spark-master"
  sudo bash -c "echo 'SPARK_MASTER_IP=#{ip_address} >> #{bdp_path}/priv/spark-master/conf/spark-env.sh'"
 
  # configure riak
  echo "configuring riak"
  sudo sed -i bak 's/distributed_cookie = .*/distributed_cookie = riak_bdp/' #{bdp_path}/etc/riak.conf
  sudo sed -i bak 's/nodename = .*/nodename = riak_bdp_#{node_number}@#{ip_address}/' #{bdp_path}/etc/riak.conf
  sudo sed -i bak 's/listener.http.internal = .*/listener.http.internal = #{ip_address}:8098/' #{bdp_path}/etc/riak.conf
  sudo sed -i bak 's/listener.protobuf.internal = .*/listener.protobuf.internal = #{ip_address}:8087/' #{bdp_path}/etc/riak.conf
  sudo bash -c "# Added by Vagrant provisioning' >> #{bdp_path}/etc/riak.conf"
  sudo bash -c "echo 'handoff.ip = #{ip_address}' >> #{bdp_path}/etc/riak.conf"
  if [[ "#{$oss}" -eq 0 ]]; then
    # leader election service is an EE feature
    sudo bash -c "echo 'listener.leader_latch.internal = #{ip_address}:5323' >> #{bdp_path}/etc/riak.conf"
    sudo bash -c "echo 'listener.leader_latch.external = #{ip_address}:15323' >> #{bdp_path}/etc/riak.conf"
  fi

sudo bash -c "cat <<EOF_LAUNCH > /Library/LaunchDaemons/com.basho.riak.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC -//Apple Computer//DTD PLIST 1.0//EN
          http://www.apple.com/DTDs/PropertyList-1.0.dtd >
<plist version="1.0">
    <dict>
         <key>Label</key>
         <string>com.basho.riak</string>
         <key>UserName</key>
         <string>riak</string>
         <key>SoftResourceLimits</key>
         <dict>
             <key>NumberOfFiles</key>
             <integer>65536</integer>
             <key>NumberOfProcesses</key>
             <integer>2048</integer>
         </dict>
         <key>HardResourceLimits</key>
         <dict>
             <key>NumberOfFiles</key>
             <integer>65536</integer>
             <key>NumberOfProcesses</key>
             <integer>2048</integer>
         </dict>
         <key>RunAtLoad</key>
         <true/>
         <key>KeepAlive</key>
         <false/>
         <key>WorkingDirectory</key>
         <string>#{bdp_path}</string>
         <key>ProgramArguments</key>
         <array>
             <string>#{bdp_path}/bin/riak</string>
             <string>start</string>
         </array>
         <key>StandardErrorPath</key>
         <string>#{bdp_path}/log/launch.error.log</string>
         <key>StandardOutPath</key>
         <string>#{bdp_path}/log/launch.out.log</string>
      </dict>
</plist>
EOF_LAUNCH
"

  # HACK: code:priv_dir(data_platform) is resolving to the wrong path for OSX
  # IS: "/usr/lib/riak/lib/data_platform-1/lib/data_platform-1/priv"
  # SHOULD BE:
  # "/usr/lib/riak/lib/data_platform-1/priv"
  # using an otherwise harmlessi set of symlinks to assure correct paths
  for i in `ls -d /usr/lib/riak/lib/data_platform-1/priv/*`; do
    sudo ln -s $i /usr/lib/riak/lib/data_platform-1/lib/data_platform-1/priv
  done

  echo "restarting Riak"
  sudo launchctl load /Library/LaunchDaemons/com.basho.riak.plist
  sudo launchctl start com.basho.riak

  BDP_HOME=$(dirname $(which data-platform-admin))
  echo "BDP installed, BDP home: $BDP_HOME"
fi

EOF
end

# ensure download has been run, it's re-entrant
system('./bin/download.sh')

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

      if $target_vm == 'osx'
        # Temporary fix for annoying "Replace key" issue
        n.ssh.insert_key = false

        # Use NFS for the shared folder
        n.vm.synced_folder "downloads/", "/users/vagrant/Downloads",
          id: "core",
          nfs: true,
          mount_options: ['nolock,vers=3,udp,noatime']
      else
        n.vm.synced_folder "downloads/", "/home/vagrant/downloads"
      end

      n.vm.network "private_network", ip: opts[:ip_address]

      # limit memory consumption
      n.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
      end

      if $target_vm == 'osx'
        n.vm.provider "virtualbox" do |vb|
          # Fix "hfs mounted macintosh hd on device root_device" issue
          vb.customize ["modifyvm", :id, "--cpuidset", "1","000206a7","02100800","1fbae3bf","bfebfbff"]
          # Some more hacks for device recognition
          vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct", "MacBookPro11,3"]
          vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion", "1.0"]
          vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct", "Iloveapple"]
          vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/DeviceKey", "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"]
          vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC", "1"]
        end
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

