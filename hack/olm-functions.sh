  function update_bundle_image() {
    environment=${1:-"devel"}
    BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$BASEDIR")"

    echo "Getting bundle image for environment: $environment" >&2
    TARGET_REGISTRY=$(target_registry $environment)
    echo "Target registry: $TARGET_REGISTRY" >&2
    BUNDLE_IMAGE=$(yq '.images[] | select(.name == "IMAGE_OPERATOR_BUNDLE") | .value' project.yaml)
    echo "Original bundle image: $BUNDLE_IMAGE" >&2
    BUNDLE_JSON=$(opm render --skip-tls-verify -o json ${BUNDLE_IMAGE})
    BUNDLE_NAME=$(echo $BUNDLE_JSON | jq -r '.name')
    BUNDLE_VERSION=$(echo $BUNDLE_NAME | awk -F 'v' '{ print $2 }')
    echo "BUNDLE_NAME : $BUNDLE_NAME"
    echo "Bundle Version : $BUNDLE_VERSION"

    SOURCE_PATTEN="quay.io/.*/(.*)-rhel8(@sha256:.+)"
    TARGET_PATTEN="$TARGET_REGISTRY/pipelines-\1\2"
    BUNDLE_IMAGE=$(echo "${BUNDLE_IMAGE}" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")
    echo "Updated bundle image: $BUNDLE_IMAGE" >&2

    #Update the bundle image and version in the olm config.yaml file only for 5.0.x versions
    export BUNDLE_IMAGE BUNDLE_VERSION
    yq -i e '(.bundles[] | select(.version | test("^5\\.0\\..*"))).image = env(BUNDLE_IMAGE)' $ROOT_DIR/olm/config.yaml
    yq -i e '(.bundles[] | select(.version == env(BUNDLE_VERSION))).image = env(BUNDLE_IMAGE)' $ROOT_DIR/olm/config.yaml
}

function target_registry() {
  environment=$1
  echo "Determining target registry for environment: $environment" >&2
  case "$environment" in
    "staging")
      TARGET_REGISTRY="registry.stage.redhat.io/openshift-pipelines"
      ;;
    "production")
      TARGET_REGISTRY="registry.redhat.io/openshift-pipelines"
      ;;
    *)
      TARGET_REGISTRY="quay.io/openshift-pipeline"
      ;;
  esac
  echo "Selected target registry: $TARGET_REGISTRY" >&2
  echo $TARGET_REGISTRY
}

#
function render_catalog() {
    VERSION=$1
    CATALOG_JSON=$2
    RENDERED_CATALOG_JSON=$3
    NUMERIC_VERSION=${VERSION#v} # Removes "v" prefix

    if (( $(echo "$NUMERIC_VERSION >= 4.17" | bc -l) )); then
        opm alpha render-template basic $CATALOG_JSON --migrate-level=bundle-object-to-csv-metadata > $RENDERED_CATALOG_JSON
    else
      opm alpha render-template basic $CATALOG_JSON > $RENDERED_CATALOG_JSON
    fi
    echo "Render template for $VERSION Done"

}
