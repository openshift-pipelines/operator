  function get_bundle_image() {
    environment=${1:-"devel"}
    echo "Getting bundle image for environment: $environment" >&2
    TARGET_REGISTRY=$(target_registry $environment)
    echo "Target registry: $TARGET_REGISTRY" >&2
    BUNDLE_IMAGE=$(yq '.images[] | select(.name == "IMAGE_OPERATOR_BUNDLE") | .value' project.yaml)
    echo "Original bundle image: $BUNDLE_IMAGE" >&2
    BUNDLE_JSON=$(opm render --skip-tls-verify -o json ${BUNDLE_IMAGE})

    SOURCE_PATTEN="quay.io/.*/(.*)-rhel9(@sha256:.+)"
    TARGET_PATTEN="$TARGET_REGISTRY/pipelines-\1\2"
    BUNDLE_IMAGE=$(echo "${BUNDLE_IMAGE}" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")
    echo "Updated bundle image: $BUNDLE_IMAGE" >&2
    echo $BUNDLE_IMAGE
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
