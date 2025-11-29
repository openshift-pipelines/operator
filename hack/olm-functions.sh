  function validate_bundles(){
    BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$BASEDIR")"
    LENGTH=$(yq e '.bundles | length' $ROOT_DIR/olm/config.yaml)
    echo "Total Bundles : $LENGTH"
    for i in $(seq 0 $((${LENGTH}-1))); do
        version=$(yq e ".bundles.${i}.version" $ROOT_DIR/olm/config.yaml)
        image=$(yq e ".bundles.${i}.image" $ROOT_DIR/olm/config.yaml)
        BUNDLE_JSON=$(opm render $image)
        BUNDLE_NAME=$(echo $BUNDLE_JSON | jq -r '.name')
        BUNDLE_VERSION=$(echo $BUNDLE_NAME | awk -F 'v' '{ print $2 }')
        echo -e "$image \n \t Bundle Version: $BUNDLE_VERSION\n\t Config Version: $version "

        if [[ $version != $BUNDLE_VERSION ]] ; then
          echo -e "❌ Bundle image  for $version is not correct in config \e[0m" >&2
          exit 1
        fi
    done
    echo "All Bundle Images are configured correctly"
  }

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

    SOURCE_PATTEN="quay.io/.*/(.*@sha256:.+)"
    TARGET_PATTEN="$TARGET_REGISTRY/\1"
    BUNDLE_IMAGE=$(echo "${BUNDLE_IMAGE}" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")
    echo "Updated bundle image: $BUNDLE_IMAGE" >&2

    #Update the bundle image and version in the olm config.yaml file only for 5.0.x versions
    BASE_VERSION=${BUNDLE_VERSION%%-*}
    yq -i e "(.bundles[] | select(.version | test(\"^$BASE_VERSION.*\"))).image = \"${BUNDLE_IMAGE}\"" $ROOT_DIR/olm/config.yaml
    yq -i e "(.bundles[] | select(.version | test(\"^$BASE_VERSION.*\"))).version = \"${BUNDLE_VERSION}\"" $ROOT_DIR/olm/config.yaml
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
    validate_bundles
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

function update_olm_version() {
  current_version=$(yq e '.versions.current' project.yaml)
  echo "Current version: $current_version"

  # Check if version contains suffix like X.Y.Z-N
  if [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]; then
      echo "Pattern: semantic version with suffix"

      # Extract suffix
      suffix_number=${current_version##*-}
      new_suffix_number=$(( suffix_number + 1 ))

      # Extract base version
      base_version=${current_version%-*}

      # Construct new version
      new_version="$base_version-$new_suffix_number"
      echo "New version: $new_version"

      # Update project.yaml
      yq -i e ".versions.current = \"$new_version\"" project.yaml
      yq -i e ".versions.previous = \"$current_version\"" project.yaml

  else
      echo "Pattern: semantic only (X.Y.Z), no bump"
      new_version="$current_version"     # use same version for sync
  fi

  # Always sync version to Dockerfile and catalog JSON
  echo "Syncing version to Dockerfile & catalog templates..."
  sed -Ei "s%version=.*\\\%version=\"$new_version\" \\\%g" .konflux/olm-catalog/bundle/Dockerfile


  echo "Done"
}
