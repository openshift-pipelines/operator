#!/usr/bin/env bash

set -ex
current_version=$(cat hack/version)
echo $current_version
current_version_number=${current_version##*-}
echo $current_version_number
new_version_number=$(( current_version_number + 1 ))
echo $new_version_number
new_version1=(${current_version//-/ })
new_version2=$new_version1-$new_version_number
echo "$new_version2"
echo "$new_version2" > "hack/version"

# update version and previous_version in operator-fetch-payload

sed -i "s/CURRENT_VERSION=.*/CURRENT_VERSION=$new_version2/" hack/operator-fetch-payload.sh
sed -i "s/PREVIOUS_VERSION=.*/PREVIOUS_VERSION=$current_version/" hack/operator-fetch-payload.sh
