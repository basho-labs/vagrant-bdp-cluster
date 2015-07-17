#! /bin/bash
# target vm box type, supports: centos or ubuntu, default: centos
export TARGET_VM=${TARGET_VM:-"centos"}
# target vm count, supports: 1..as much as your hardware allows, default: 3
export TARGET_VM_COUNT=${TARGET_VM_COUNT:-3}
# url for the bdp rpm package for centos
export DOWNLOAD_BDP_PACKAGE_CENTOS_URL=""
# url for the bdp extras tarball for centos
export DOWNLOAD_BDP_EXTRAS_CENTOS_URL=""
# url for the bdp deb package for ubuntu
export DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=""
# url for the bdp extras tarball for ubuntu
export DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=""

