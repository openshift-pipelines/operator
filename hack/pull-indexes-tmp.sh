#!/bin/bash

set -e

versions=("v4.15" "v4.16" "v4.17" "v4.18")
TMP_DIR="tmp"

mkdir -p "${TMP_DIR}"

for version in "${versions[@]}"; do
  echo "Rendering index for ${version}..."
  opm render "registry.redhat.io/redhat/redhat-operator-index:${version}" > "${TMP_DIR}/target-index-${version}.json"
done

echo "All indexes rendered successfully in ${TMP_DIR}/" 