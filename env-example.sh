#! /bin/bash
if [[ "$@" =~ "-f" ]]; then
    echo "forcing new environment"
    OSS=""
    TARGET_VM=""
    TARGET_VM_VARIANT=""
    TARGET_VM_COUNT=""
    DOWNLOAD_BDP_PACKAGE_CENTOS_URL=""
    DOWNLOAD_BDP_EXTRAS_CENTOS_URL=""
    DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=""
    DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=""
    DOWNLOAD_BDP_PACKAGE_DEBIAN_URL=""
    DOWNLOAD_BDP_EXTRAS_DEBIAN_URL=""
    DOWNLOAD_BDP_PACKAGE_OSX_URL=""
    DOWNLOAD_BDP_EXTRAS_OSX_URL=""
fi

# whether BDP is Enterprise Edition (EE) or Open Source Software (OSS), default: 0 (not OSS, so EE)
export OSS=${OSS:-0}
# target vm box type, supports: centos or ubuntu, default: centos
export TARGET_VM=${TARGET_VM:-"centos"}
# target vm variant, supports:
#   centos: 6 or 7, default: 6
#   ubuntu: precise (12.04) or trusty (14.04), default: precise
#   debian: wheezy (7) or jessie (8), default wheezy
#   osx: yosemite (10.10), default yosemite
export TARGET_VM_VARIANT=${TARGET_VM_VARIANT:-"6"}
# target vm count, supports: 1..as much as your hardware allows, default: 3
export TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}
# url for the bdp core package for centos
export DOWNLOAD_BDP_PACKAGE_CENTOS_URL=""
# url for the bdp extras package for centos
export DOWNLOAD_BDP_EXTRAS_CENTOS_URL=""
# url for the bdp core package for ubuntu
export DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=""
# url for the bdp extras package for ubuntu
export DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=""
# url for the bdp core package for debian
export DOWNLOAD_BDP_PACKAGE_DEBIAN_URL=""
# url for the bdp extras package for debian
export DOWNLOAD_BDP_EXTRAS_DEBIAN_URL=""
# url for the bdp core package for OSX
export DOWNLOAD_BDP_PACKAGE_OSX_URL=""
# url for the bdp extras package for OSX
export DOWNLOAD_BDP_EXTRAS_OSX_URL=""

if [[ $TARGET_VM_COUNT < 3 ]]; then
    cat <<EOF
BDP must have at least 3 nodes. Less than 3 nodes is only useful for testing
vagrant provisioning.
EOF
fi

cat <<EOF
Environment
===========
OSS:               $OSS
TARGET_VM:         $TARGET_VM
TARGET_VM_VARIANT: $TARGET_VM_VARIANT
TARGET_VM_COUNT:   $TARGET_VM_COUNT
EOF
