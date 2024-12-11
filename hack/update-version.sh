#!/usr/bin/env bash

set -ex
current_version=$(yq e '.versions.current' project.yaml)
echo $current_version
current_version_number=${current_version##*-}
echo $current_version_number
new_version_number=$(( current_version_number + 1 ))
echo $new_version_number
new_version1=(${current_version//-/ })
new_version2=$new_version1-$new_version_number
echo "$new_version2"
yq -i e ".versions.current = \"$new_version2\"" project.yaml
yq -i e ".versions.previous = \"$current_version\"" project.yaml

# update version and previous_version in operator-fetch-payload
sed -i "s%version=.*\\\%version=\"$new_version2\" \\\%g" .konflux/olm-catalog/bundle/Dockerfile
for v in .konflux/olm-catalog/index/v*; do
    sed -i "s%$current_version%$new_version2%g" $v/catalog-template.json
done
