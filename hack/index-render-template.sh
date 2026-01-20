#!/usr/bin/env bash

# Update BUNDLE_NAME for each release according to the corresponding 'name' value specified in the catalog-template.json file.
# ex: for 1.19 it will be openshift-pipelines-operator-rh.v1.19.0, for 1.17.2 it will be openshift-pipelines-operator-rh.v1.17.2
BUNDLE_NAME=openshift-pipelines-operator-rh.v1.15.4

# Update images from project.yaml to "generated" files
VERSION=${1:-"v4.18"}
ENVIRONMENT=${2:-"devel"}

CATALOG_JSON=".konflux/olm-catalog/index/${VERSION}/catalog-template.json"
BUNDLE_IMAGE=$(yq '.images[] | select(.name == "IMAGE_OPERATOR_BUNDLE") | .value' project.yaml)
echo "Bundle Image from project.yaml : $BUNDLE_IMAGE"

case "$ENVIRONMENT" in
  "devel")
    TARGET_REGISTRY="quay.io/openshift-pipeline"
    ;;
  "staging")
    TARGET_REGISTRY="registry.stage.redhat.io/openshift-pipelines"
    ;;
  "production")
    TARGET_REGISTRY="registry.redhat.io/openshift-pipelines"
    ;;
  *)
    echo "Invalid selection!"
    exit 1
    ;;
esac

SOURCE_PATTEN="quay.io/.*/(.*)-rhel8(@sha256:.+)"
TARGET_PATTEN="$TARGET_REGISTRY/pipelines-\1\2"
BUNDLE_IMAGE=$(echo "${BUNDLE_IMAGE}" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")
echo "Bundle Image updated for index images : $BUNDLE_IMAGE"

## Update the image field with $BUNDLE_IMAGE
## There are multiple olm.bundle entries for all previously released versions.
## jq query ensure proper replacement based on BUNDLE_NAME.
jq --arg BUNDLE_IMAGE "$BUNDLE_IMAGE" --arg BUNDLE_NAME "$BUNDLE_NAME" '.entries |= map(if .schema == "olm.bundle" and .name == $BUNDLE_NAME then .image = $BUNDLE_IMAGE else . end)' "$CATALOG_JSON" > temp.json && mv temp.json "$CATALOG_JSON"
echo "Update bundle Image in $CATALOG_JSON"

BUNDLE_VERSION=$(opm render --skip-tls-verify -o json ${BUNDLE_IMAGE} | jq -r '.name' | awk -F 'v' '{ print $2 }')

# Update catalog-template
sed -i "s%5.0.5-[0-9]\+%${BUNDLE_VERSION}%g" .konflux/olm-catalog/index/${VERSION}/catalog-template.json

# as per this doc https://github.com/konflux-ci/olm-operator-konflux-sample/blob/main/docs/konflux-onboarding.md#create-the-fbc-in-the-git-repository
# Starting with OCP 4.17 we need the --migrate-level=bundle-object-to-csv-metadata flag. For rendering to older versions of OCP.
NUMERIC_VERSION=${VERSION#v} # Removes "v" prefix
if (( $(echo "$NUMERIC_VERSION >= 4.17" | bc -l) )); then
  opm alpha render-template basic .konflux/olm-catalog/index/${VERSION}/catalog-template.json --migrate-level=bundle-object-to-csv-metadata > .konflux/olm-catalog/index/${VERSION}/catalog/openshift-pipelines-operator-rh/catalog.json
else
  opm alpha render-template basic .konflux/olm-catalog/index/${VERSION}/catalog-template.json > .konflux/olm-catalog/index/${VERSION}/catalog/openshift-pipelines-operator-rh/catalog.json
fi