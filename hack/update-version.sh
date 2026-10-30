#!/usr/bin/env bash

set -ex
bundle_dockerfile=.konflux/dockerfiles/bundle.Dockerfile

current_version=$(yq e '.versions.current' project.yaml)
echo "Current version: $current_version"

new_version=$(sed -n 's/^[[:space:]]*version="\([^"]*\)".*/\1/p' "$bundle_dockerfile")
new_version="${new_version#v}"

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
  echo "Version unchanged; project.yaml not updated"
fi
