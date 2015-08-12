#! /bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function url_filename () {
    local URL=$1
    if [[ "$URL" == "" ]]; then return; fi

    URL_FILENAME=$(echo "$URL" |tr '/' '\n' |tail -n 1)
    if [[ "$URL_FILENAME" =~ "?" ]]; then
        URL_FILENAME=$(echo "$URL_FILENAME" |tr '?' '\n' |head -n 1)
    fi
    if [[ "$URL_FILENAME" == "" ]]; then
        URL_FILENAME="index"
    fi
}

url_extension () {
    local URL=$1
    url_filename "$URL"
    if [[ "$URL_FILENAME" == "" ]]; then return; fi
    local PARTS=$(echo "$URL_FILENAME" |tr '.' '\n')
    local FIRST_PART=1
    URL_EXTENSION=""
    for PART in $PARTS; do
        if [[ $FIRST_PART == 1 ]]; then
            FIRST_PART=0
        else
            # file extension is only numeric
            if [[ $PART =~ ^[0-9]+$ ]]; then
                URL_EXTENSION=""
            elif [[ $PART =~ [^A-Za-z0-9] ]]; then
                URL_EXTENSION=""
            else
                URL_EXTENSION="$URL_EXTENSION.$PART"
            fi  
        fi
    done
    if [[ "$URL_EXTENSION" != "" ]]; then
        URL_EXTENSION=${URL_EXTENSION:1}
    fi
} 

DOWNLOAD_JAVA_URL=${DOWNLOAD_JAVA_URL:-"http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.rpm"}
DOWNLOAD_JAVA_FILE=${DOWNLOAD_JAVA_FILE:-"jdk-8.rpm"}
DOWNLOAD_BDP_PACKAGE_CENTOS_URL=${DOWNLOAD_BDP_PACKAGE_CENTOS_URL:-""}
if [[ "$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE" == "" ]]; then
    url_extension "$DOWNLOAD_BDP_PACKAGE_CENTOS_URL"
    DOWNLOAD_BDP_PACKAGE_CENTOS_FILE="basho-data-platform-CENTOS.$URL_EXTENSION"
fi
DOWNLOAD_BDP_EXTRAS_CENTOS_URL=${DOWNLOAD_BDP_EXTRAS_CENTOS_URL:-""}
if [[ "$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE" == "" ]]; then
    url_extension "$DOWNLOAD_BDP_EXTRAS_CENTOS_URL"
    DOWNLOAD_BDP_EXTRAS_CENTOS_FILE="basho-data-platform-extras-CENTOS.$URL_EXTENSION"
fi
DOWNLOAD_BDP_PACKAGE_UBUNTU_URL=${DOWNLOAD_BDP_PACKAGE_UBUNTU_URL:-""}
if [[ "$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE" == "" ]]; then
    url_extension "$DOWNLOAD_BDP_PACKAGE_UBUNTU_URL"
    DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE="basho-data-platform-UBUNTU.$URL_EXTENSION"
fi
DOWNLOAD_BDP_EXTRAS_UBUNTU_URL=${DOWNLOAD_BDP_EXTRAS_UBUNTU_URL:-""}
if [[ "$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE" == "" ]]; then
    url_extension "$DOWNLOAD_BDP_EXTRAS_UBUNTU_URL"
    DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE="basho-data-platform-extras-UBUNTU.$URL_EXTENSION"
fi

DOWNLOAD_JAVA_FILE="$DIR/../downloads/$DOWNLOAD_JAVA_FILE"
DOWNLOAD_BDP_PACKAGE_CENTOS_FILE="$DIR/../downloads/$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE"
DOWNLOAD_BDP_EXTRAS_CENTOS_FILE="$DIR/../downloads/$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE"
DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE="$DIR/../downloads/$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE"
DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE="$DIR/../downloads/$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE"

# centos
if [[ ! -e "$DOWNLOAD_JAVA_FILE" && "$DOWNLOAD_JAVA_URL" != "" ]]; then
    wget -O "$DOWNLOAD_JAVA_FILE" --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$DOWNLOAD_JAVA_URL"
    if [[ $? != 0 ]]; then
        echo "failed to download jdk 8 package"
        exit
    fi
fi

if [[ ! -e "$DOWNLOAD_BDP_PACKAGE_CENTOS_FILE" && "$DOWNLOAD_BDP_PACKAGE_CENTOS_URL" != "" ]]; then
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

# expand tarball, if needed
url_extension "$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE"
if [[ "$URL_EXTENSION" == "tar.gz" ]]; then
    mkdir "$DIR/../downloads/basho-data-platform-extras-CENTOS/"
    tar -C "$DIR/../downloads/basho-data-platform-extras-CENTOS/" --strip-components=1 -xzf "$DOWNLOAD_BDP_EXTRAS_CENTOS_FILE"
fi

# ubuntu
if [[ ! -e "$DOWNLOAD_BDP_PACKAGE_UBUNTU_FILE" && "$DOWNLOAD_BDP_PACKAGE_UBUNTU_URL" != "" ]]; then
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

# expand tarball, if needed
url_extension "$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE"
if [[ "$URL_EXTENSION" == "tar.gz" ]]; then
    mkdir "$DIR/../downloads/basho-data-platform-extras-UBUNTU/"
    tar -C "$DIR/../downloads/basho-data-platform-extras-UBUNTU/" --strip-components=1 -xzf "$DOWNLOAD_BDP_EXTRAS_UBUNTU_FILE"
fi

