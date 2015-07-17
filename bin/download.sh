#! /bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DOWNLOAD_JAVA_URL=${DOWNLOAD_JAVA_URL:-"http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.rpm"}
DOWNLOAD_JAVA_FILE=${DOWNLOAD_JAVA_FILE:-"jdk-8.rpm"}
DOWNLOAD_BDP_PACKAGE_CENTOS_URL=${DOWNLOAD_BDP_PACKAGE_CENTOS_URL:-""}
DOWNLOAD_BDP_PACKAGE_CENTOS_FILE=${DOWNLOAD_BDP_PACKAGE_CENTOS_FILE:-"basho-data-platform.rpm"}
DOWNLOAD_BDP_EXTRAS_CENTOS_URL=${DOWNLOAD_BDP_EXTRAS_CENTOS_URL:-""}
DOWNLOAD_BDP_EXTRAS_CENTOS_FILE=${DOWNLOAD_BDP_EXTRAS_CENTOS_FILE:-"basho-data-platform-extras-centos.tar.gz"}
DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=${DOWNLOAD_BDP_PACKAGE_UBUNTU_URL:-""}
DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE=${DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE:-"basho-data-platform.deb"}
DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=${DOWNLOAD_BDP_EXTRAS_UBUNTU_URL:-""}
DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE=${DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE:-"basho-data-platform-extras-ubuntu.tar.gz"}

DOWNLOAD_JAVA_FILE="$DIR/../downloads/$DOWNLOAD_JAVA_FILE"
DOWNLOAD_BDP_PACKAGE_CENTOS_FILE="$DIR/../downloads/$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE"
DOWNLOAD_BDP_EXTRAS_CENTOS_FILE="$DIR/../downloads/$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE"
DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE="$DIR/../downloads/$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE"
DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE="$DIR/../downloads/$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE"

# centos
if [[ ! -e "$DOWNLOAD_JAVA_FILE" ]]; then
    wget -O "$DOWNLOAD_JAVA_FILE" --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$DOWNLOAD_JAVA_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download jdk 8 package"
        exit
    fi
fi

if [[ ! -e "$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE" ]]; then
    wget -O "$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE" "$DOWNLOAD_BDP_PACKAGE_CENTOS_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download bdp package for centos"
        exit
    fi
    wget -O "$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE" "$DOWNLOAD_BDP_EXTRAS_CENTOS_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download bdp extras for centos"
        exit
    fi
fi

# ubuntu
if [[ ! -e "$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE" ]]; then
    wget -O "$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE" "$DOWNLOAD_BDP_PACKAGE_UBUNTU_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download bdp package for ubuntu"
    fi
    wget -O "$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE" "$DOWNLOAD_BDP_EXTRAS_UBUNTU_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download bdp tarball for ubuntu"
        exit
    fi
fi
