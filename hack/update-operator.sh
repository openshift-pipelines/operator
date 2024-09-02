#!/usr/bin/env bash
# Update operator in upstream folder.
set -euo pipefail

# Get URL and branch to get components.yaml from.
URL=$(yq e ".git[0].url" sources.yaml)
BRANCH=$(yq e ".git[0].branch" sources.yaml)
# Resolve commits
# Old commit
OLD_COMMIT=$(yq e ".git[0].commit" sources.yaml)
COMMIT=$(git ls-remote ${URL} refs/heads/${BRANCH} | awk '{print $1 }')

if [[ "${COMMIT}" = "${OLD_COMMIT}" ]]; then
   echo "No update detected (revision ${BRANCH} (from ${URL}) at ${COMMIT}), doing nothing…"
   exit 0
fi

echo "Updating sources.yaml"
yq e -i ".git[0].url = \"${URL}\"" sources.yaml
yq e -i ".git[0].branch = \"${BRANCH}\"" sources.yaml
yq e -i ".git[0].commit = \"${COMMIT}\"" sources.yaml

# Run make "inception"
make ".sources/operator.${COMMIT}"
