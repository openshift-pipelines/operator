#!/usr/bin/env bash
# Update createdAt annotation in CSV file to current timestamp
# Only updates if the CSV file has changes (excluding createdAt itself)
set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$BASEDIR")"

CSV_FILE="$ROOT_DIR/.konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml"

if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: CSV file not found at $CSV_FILE"
    exit 1
fi

# Check if CSV file has been modified compared to git index (excluding createdAt changes)
if ! git diff --quiet "$CSV_FILE" 2>/dev/null; then
    # File has changes - check if it's more than just createdAt
    DIFF_EXCLUDING_CREATEDAT=$(git diff "$CSV_FILE" | grep -E '^[+-]' | grep -v '^+++' | grep -v '^---' | grep -v 'createdAt:' || true)

    if [ -n "$DIFF_EXCLUDING_CREATEDAT" ]; then
        # Real changes detected (not just createdAt), update timestamp
        CREATED_AT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        env CREATED_AT_TIMESTAMP="${CREATED_AT_TIMESTAMP}" yq e -i \
           '.metadata.annotations.createdAt = strenv(CREATED_AT_TIMESTAMP)' \
           "$CSV_FILE"

        echo "Updated createdAt annotation to: $CREATED_AT_TIMESTAMP"
    else
        echo "Only createdAt changes detected, skipping timestamp update"
    fi
else
    echo "No changes detected in CSV file, skipping timestamp update"
fi
