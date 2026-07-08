log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
    echo "[$timestamp] [$level] $message"
}
  function update_bundle_image() {
    environment=${1:-"devel"}
    BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$BASEDIR")"

    log "INFO" "Getting bundle image for environment: $environment" >&2
    TARGET_REGISTRY=$(target_registry $environment)
    log "INFO" "Target registry: $TARGET_REGISTRY" >&2
    BUNDLE_IMAGE=$(yq '.images[] | select(.name == "IMAGE_OPERATOR_BUNDLE") | .value' bundle.yaml)
    log "INFO" "Original bundle image: $BUNDLE_IMAGE" >&2
    BUNDLE_JSON=$(opm render --skip-tls-verify -o json ${BUNDLE_IMAGE})
    BUNDLE_NAME=$(echo $BUNDLE_JSON | jq -r '.name')
    BUNDLE_VERSION=$(echo $BUNDLE_NAME | awk -F 'v' '{ print $2 }')
    log "INFO" "BUNDLE_NAME : $BUNDLE_NAME"
    log "INFO" "Bundle Version : $BUNDLE_VERSION"

    SOURCE_PATTEN="quay.io/.*/(.*@sha256:.+)"
    TARGET_PATTEN="$TARGET_REGISTRY/\1"
    BUNDLE_IMAGE=$(echo "${BUNDLE_IMAGE}" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")
    log "INFO" "Updated bundle image: $BUNDLE_IMAGE" >&2

    #Update the bundle image and version in the olm config.yaml file only for 5.0.x versions
    FILE="$ROOT_DIR/olm/config.yaml"
    if [[ "$BUNDLE_VERSION" == *-* ]]; then
        BASE_VERSION="${BUNDLE_VERSION%-*}"
    else
        BASE_VERSION="$BUNDLE_VERSION"
    fi

  export BUNDLE_IMAGE BUNDLE_VERSION
  log "INFO" "Replacing the last bundle entry with version $BUNDLE_VERSION"
  # The [-1] index specifically targets the final item in the array
  yq -i '.bundles[-1].version = env(BUNDLE_VERSION) | .bundles[-1].image = env(BUNDLE_IMAGE)' "$FILE"
}

function target_registry() {
  environment=$1
  log "INFO" "Determining target registry for environment: $environment" >&2
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
  log "INFO" "Selected target registry: $TARGET_REGISTRY" >&2
  echo $TARGET_REGISTRY
}

#
function render_catalog() {
    VERSION=$1
    CATALOG_JSON=$2
    RENDERED_CATALOG_JSON=$3
    NUMERIC_VERSION=${VERSION#v} # Removes "v" prefix

    if (( $(awk -v ver="$NUMERIC_VERSION" 'BEGIN { print (ver >= 4.17) }') )); then
        opm alpha render-template basic $CATALOG_JSON --migrate-level=bundle-object-to-csv-metadata > $RENDERED_CATALOG_JSON
    else
      opm alpha render-template basic $CATALOG_JSON > $RENDERED_CATALOG_JSON
    fi
    log "INFO" "Render template for $VERSION Done"
}

