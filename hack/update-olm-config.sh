#!/usr/bin/env bash
set -e
ENVIRONMENT=${1:-"devel"}

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$BASEDIR")"

source $BASEDIR/olm-functions.sh

BUNDLE_IMAGE=$(get_bundle_image $ENVIRONMENT)
# Get the current version from project.yaml
BUNDLE_VERSION=$(yq '.versions.current' project.yaml)
echo "Bundle Version: $BUNDLE_VERSION"
#Update the bundle image and version in the olm config.yaml file only for 5.0.x versions
export BUNDLE_IMAGE BUNDLE_VERSION
yq -i e '(.bundles[] | select(.version | test("^5\\.0\\..*"))).image = env(BUNDLE_IMAGE)' $ROOT_DIR/olm/config.yaml
yq -i e '(.bundles[] | select(.version | test("^5\\.0\\..*"))).version = env(BUNDLE_VERSION)' $ROOT_DIR/olm/config.yaml

