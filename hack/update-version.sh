#!/usr/bin/env bash

set -ex
current_version=$(yq e '.versions.current' project.yaml)
echo "Current version: $current_version"

new_version="$current_version"
# Only bump if version ends with -<number>
if [[ "$current_version" =~ ^(.+)-([0-9]+)$ ]]; then
  base="${BASH_REMATCH[1]}"
  suffix="${BASH_REMATCH[2]}"
  new_version="${base}-$((suffix + 1))"
fi
echo "New version: $new_version"

# Update YAML only if version changed
if [[ "$new_version" != "$current_version" ]]; then
  yq -i e ".versions.previous = \"$current_version\"" project.yaml
  yq -i e ".versions.current  = \"$new_version\"" project.yaml
else
  echo "No numeric suffix found; version not updated in project.yaml"
fi
# update version and previous_version in operator-fetch-payload
sed -i."" "s%version=.*\\\%version=\"$new_version\" \\\%g" .konflux/dockerfiles/bundle.Dockerfile
