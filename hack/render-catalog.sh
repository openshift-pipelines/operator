#!/usr/bin/env bash
set -e
ENVIRONMENT=${1:-"devel"}
OCP_VERSIONS=${2:-"ALL_VERSIONS"}



BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $BASEDIR/olm-functions.sh

ROOT_DIR="$(dirname "$BASEDIR")"
OLM_DIR="$ROOT_DIR/.konflux/olm-catalog"


if [ "$OCP_VERSIONS" == "ALL_VERSIONS" ]; then
  OCP_VERSIONS=()
  for d in "$OLM_DIR/index"/*/; do
    [ -d "$d" ] && OCP_VERSIONS+=("$(basename "$d")")
  done
else
  OCP_VERSIONS=("$OCP_VERSIONS")
fi


BUNDLE_IMAGE=$(get_bundle_image $ENVIRONMENT)
# Get the current version from project.yaml
BUNDLE_VERSION=$(yq '.versions.current' project.yaml)
echo "Bundle Version: $BUNDLE_VERSION"
#Update the bundle image and version in the olm config.yaml file only for 5.0.x versions
export BUNDLE_IMAGE BUNDLE_VERSION
yq -i e '(.bundles[] | select(.version | test("^5\\.0\\..*"))).image = env(BUNDLE_IMAGE)' $ROOT_DIR/olm/config.yaml
yq -i e '(.bundles[] | select(.version | test("^5\\.0\\..*"))).version = env(BUNDLE_VERSION)' $ROOT_DIR/olm/config.yaml


# Generate the catalog for each version
for VERSION in ${OCP_VERSIONS[@]}; do
  echo "Generating catalog for $VERSION"
  CATALOG_JSON="$OLM_DIR/index/${VERSION}/catalog-template.json"
  RENDERED_CATALOG_JSON="$OLM_DIR/index/${VERSION}/catalog/openshift-pipelines-operator-rh/catalog.json"
  echo "generating catalog template $CATALOG_JSON"
  (cd $ROOT_DIR/olm && go run olm.go config.yaml $CATALOG_JSON)
  render_catalog $VERSION $CATALOG_JSON $RENDERED_CATALOG_JSON
done





