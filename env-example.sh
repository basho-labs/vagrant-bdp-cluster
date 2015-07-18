#! /bin/bash
if [[ "$@" =~ "-f" ]]; then
    echo "forcing new environment"
    TARGET_VM=""
    TARGET_VM_COUNT=""
    DOWNLOAD_BDP_PACKAGE_CENTOS_URL=""
    DOWNLOAD_BDP_EXTRAS_CENTOS_URL=""
    DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=""
    DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=""
fi

# target vm box type, supports: centos or ubuntu, default: centos
export TARGET_VM=${TARGET_VM:-"centos"}
# target vm count, supports: 1..as much as your hardware allows, default: 3
export TARGET_VM_COUNT=${TARGET_VM_COUNT:-1}
# url for the bdp rpm package for centos
export DOWNLOAD_BDP_PACKAGE_CENTOS_URL=""
# url for the bdp extras tarball for centos
export DOWNLOAD_BDP_EXTRAS_CENTOS_URL=""
# url for the bdp deb package for ubuntu
export DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=""
# url for the bdp extras tarball for ubuntu
export DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=""

if [[ $TARGET_VM_COUNT < 3 ]]; then
    cat <<EOF
BDP must have at least 3 nodes. Less than 3 nodes is only useful for testing
vagrant provisioning.
EOF
fi

echo "Environment set TARGET_VM: $TARGET_VM, TARGET_VM_COUNT: $TARGET_VM_COUNT"
