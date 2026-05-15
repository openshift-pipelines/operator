#!/usr/bin/env bash
# Fetch payload from upstream and copy it at the right place
# We assume upstream/tektoncd-operator is there
set -euo pipefail

SOURCE=upstream
# PREVIOUS_VERSION is used in replaces upgrade strategy
# handle 'replaces' on minor, and patch versions carefully
# see: https://redhat-internal.slack.com/archives/C06DZMC1WH2/p1712871037914189
# If it is a minor release take previos minor release
# if it is a patch release take previous version of the same release
# minor release example: new release: 1.14.0, PREVIOUS_VERSION will be 1.13.0
# patch release example: new release: 1.13.2, PREVIOUS_VERSION will be 1.13.1SOURCE=upstream/tektoncd-operator
# FIXME: figure out CURRENT_VERSION vs PREVIOUS_VERSION
CURRENT_VERSION=$(yq e '.versions.current' project.yaml)
PREVIOUS_VERSION=$(yq e '.versions.previous' project.yaml)
PREVIOUS_VERSION_RANGE=$(yq e '.versions.previous_range' project.yaml)
CHANNEL_NAME=$(yq e '.versions.channel' project.yaml)
LATEST_OPENSHIFT_VERSION=$(yq e '.versions.openshift.latest' project.yaml)
MIN_OPENSHIFT_VERSION=$(yq e '.versions.openshift.min' project.yaml)

# Check for binaries required in the script
for binary in operator-sdk kustomize yq curl; do
    command -v $binary > /dev/null 2>&1 || { echo >&2 "$binary not installed, aborting..."; exit 1; }
done

# Determine the upstream operator release branch from the downstream release config.
# We use the downstream minor version (e.g. "1.23" from CURRENT_VERSION "1.23.0") to locate
# the release-specific config file in openshift-pipelines/hack and read the operator.upstream
# field. This avoids the cherry-pick edge case where a single commit appears on multiple
# upstream release branches.
UPSTREAM_RELEASE_BRANCH=""
UPSTREAM_VERSION_TAG=""
DOWNSTREAM_MINOR_VERSION=$(echo "${CURRENT_VERSION}" | sed -E 's/^([0-9]+\.[0-9]+)\..*/\1/')
HACK_RELEASE_CONFIG_URL="https://raw.githubusercontent.com/openshift-pipelines/hack/main/config/downstream/releases/${DOWNSTREAM_MINOR_VERSION}.yaml"

echo "Fetching downstream release config from ${HACK_RELEASE_CONFIG_URL}..."
HACK_RELEASE_CONFIG=$(curl -fsSL "${HACK_RELEASE_CONFIG_URL}" || true)
if [[ -z "${HACK_RELEASE_CONFIG}" ]]; then
    echo "WARN: Failed to fetch ${HACK_RELEASE_CONFIG_URL}, falling back to 'devel'"
    UPSTREAM_VERSION_TAG="devel"
else
    UPSTREAM_RELEASE_BRANCH=$(echo "${HACK_RELEASE_CONFIG}" | yq e '.branches.operator.upstream' -)
    if [[ -z "${UPSTREAM_RELEASE_BRANCH}" || "${UPSTREAM_RELEASE_BRANCH}" == "null" ]]; then
        echo "WARN: 'branches.operator.upstream' not found in ${HACK_RELEASE_CONFIG_URL}, falling back to 'devel'"
        UPSTREAM_VERSION_TAG="devel"
    else
        UPSTREAM_MINOR_VERSION=$(echo "${UPSTREAM_RELEASE_BRANCH}" | sed -E 's/^release-v([0-9]+\.[0-9]+)\.x$/\1/')
        # Look up the latest release tag for this minor version from tektoncd/operator GitHub releases.
        UPSTREAM_VERSION_TAG=$(curl -fsSL "https://api.github.com/repos/tektoncd/operator/releases" \
            | yq e '.[] | select(.tag_name | test("^v?'"${UPSTREAM_MINOR_VERSION}"'\\.")) | .tag_name' - \
            | sort -V | tail -n1 || true)
        if [[ -z "${UPSTREAM_VERSION_TAG}" ]]; then
            echo "WARN: No upstream tag found for minor version ${UPSTREAM_MINOR_VERSION} in tektoncd/operator releases, falling back to 'devel'"
            UPSTREAM_VERSION_TAG="devel"
        fi
    fi
fi

echo "Using upstream branch '${UPSTREAM_RELEASE_BRANCH}' and latest tag '${UPSTREAM_VERSION_TAG}' for version rewrites"

echo "Fetch payloads…"
# Use our own for now
# TODO: replace with our own components.yaml
make -C ${SOURCE} TARGET=openshift COMPONENT=components.yaml get-releases

echo "Clean existings payloads…"
rm -fRv .konflux/olm-catalog/bundle/kodata

echo "Copy payloads to .konflux/olm-catalog/bundle…"
cp -rv ${SOURCE}/cmd/openshift/operator/kodata .konflux/olm-catalog/bundle/kodata

echo "Generate bundle data…"
rm -fR ${SOURCE}/operatorhub/openshift/release-artifacts/metadata/*
rm -fR ${SOURCE}/operatorhub/openshift/release-artifacts/manifest/*
export BUNDLE_ARGS="--workspace ./openshift \
                    --operator-release-version ${CURRENT_VERSION} \
                    --channels latest,${CHANNEL_NAME} \
                    --default-channel latest \
                    --fetch-strategy-local \
                    --upgrade-strategy-replaces \
                    --operator-release-previous-version openshift-pipelines-operator-rh.v${PREVIOUS_VERSION} \
                    --olm-skip-range '>=${PREVIOUS_VERSION_RANGE} <${CURRENT_VERSION}'"
make -C ${SOURCE} OPERATOR_SDK=$(which operator-sdk) operator-bundle

echo "Clean existing generated bundle data…"
rm -fRv .konflux/olm-catalog/bundle/metadata/*
rm -fRv .konflux/olm-catalog/bundle/manifests/*

echo "Copy generated bundle data to this onebundle…"
cp -rv ${SOURCE}/operatorhub/openshift/release-artifacts/bundle/metadata .konflux/olm-catalog/bundle
cp -rv ${SOURCE}/operatorhub/openshift/release-artifacts/bundle/manifests .konflux/olm-catalog/bundle


for f in .konflux/olm-catalog/bundle/manifests/*.yaml; do
    if [[ $(yq e '.metadata.labels.version' ${f}) == null ]]; then
        continue
    fi
    yq e -i ".metadata.labels.version = \"${CURRENT_VERSION}\"" ${f}
done

# Rewrite "devel" version placeholders introduced by upstream PR #3371.
# Upstream sources now use "devel" as a placeholder for version labels; the upstream
# build rewrites them at release time via sed in build-publish-images-manifests.yaml.
# The downstream must do the equivalent substitution here after bundle generation.

# Step 1: rewrite operator.tekton.dev/release and app.kubernetes.io/version annotations/labels
# across both generated bundle manifests and copied kodata payload YAMLs.
while IFS= read -r -d '' f; do
    sed -i -E \
        -e 's/(operator\.tekton\.dev\/release): "?devel"?/\1: "'"${UPSTREAM_VERSION_TAG}"'"/g' \
        -e 's/(app\.kubernetes\.io\/version): "?devel"?/\1: "'"${UPSTREAM_VERSION_TAG}"'"/g' \
        "${f}"
done < <(find .konflux/olm-catalog/bundle/manifests .konflux/olm-catalog/bundle/kodata -type f -name '*.yaml' -print0)

# Step 2: rewrite structural version fields in the CSV and ConfigMap only.
# These paths (.spec.install.spec.deployments[].label.version, .data.version) are
# specific to CSV and ConfigMap resources; applying yq to CRDs would materialise
# null nodes for those non-existent paths, polluting the CRD files.
CSV=".konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml"
OPERATOR_INFO_CM=".konflux/olm-catalog/bundle/manifests/tekton-operator-info_v1_configmap.yaml"
env UPSTREAM_VERSION_TAG="${UPSTREAM_VERSION_TAG}" yq e -i \
    '(.spec.install.spec.deployments[].label.version | select(. == "devel")) = strenv(UPSTREAM_VERSION_TAG)' \
    "${CSV}"
env UPSTREAM_VERSION_TAG="${UPSTREAM_VERSION_TAG}" yq e -i \
    '(.data.version | select(. == "devel")) = strenv(UPSTREAM_VERSION_TAG)' \
    "${OPERATOR_INFO_CM}"

# Remove label matchselector app
yq e -i 'del(.spec.install.spec.deployments[0].spec.selector.matchLabels.app)' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
yq e -i 'del(.metadata.annotations["createdAt"])' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

# Add valid-subscription annotation
yq e -i '.metadata.annotations["operators.openshift.io/valid-subscription"] = "[\"OpenShift Container Platform\", \"OpenShift Platform Plus\"]"' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml


# Update VERSION env variables in the generated CSV to the downstream OSP version.
# The upstream build may generate VERSION as "devel" (unreleased builds) or as the upstream
# tag (e.g. "0.79.1" for released tags). In both cases we unconditionally override it with
# CURRENT_VERSION so that the downstream bundle always reports the correct OSP version.
yq e -i "(.spec.install.spec.deployments[].spec.template.spec.containers[].env[] | select(.name == \"VERSION\") | .value) = \"${CURRENT_VERSION}\"" \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
# FIXME: we *may* need to clean some of those generated files

# fix serve-tkn-cli wrong image
SERVE_REF=$(yq e '.images[] | select(.name == "IMAGE_ADDONS_TKN_CLI_SERVE") | .value' project.yaml)

env SERVE_REF="$SERVE_REF" yq e -i '
(.spec.install.spec.deployments[].spec.template.spec.containers[].env[] 
  | select(.name == "IMAGE_ADDONS_TKN_CLI_SERVE")).value = strenv(SERVE_REF)' \
  .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

env SERVE_REF="$SERVE_REF" yq e -i '
(.spec.relatedImages[] 
  | select(.name == "IMAGE_ADDONS_TKN_CLI_SERVE")).image = strenv(SERVE_REF)' \
  .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

# Mutate pipelines-as-code payload
for d in controller watcher webhook; do
    yq e -i "(select (.kind == \"Deployment\") | select (.metadata.name == \"pipelines-as-code-${d}\") | .spec.template.spec.containers[0].command) = [\"/ko-app/pipelines-as-code-${d}\"]" .konflux/olm-catalog/bundle/kodata/tekton-addon/pipelines-as-code/*/release.yaml
done

# Mutate manual-approval-gate payload
for d in controller webhook; do
    yq e -i "(select (.kind == \"Deployment\") | select (.metadata.name == \"manual-approval-gate-${d}\") | .spec.template.spec.containers[0].command) = [\"/ko-app/manual-approval-gate-${d}\"]" .konflux/olm-catalog/bundle/kodata/manual-approval-gate/*/release-openshift.yaml
done

# Update the OpenShift Pipelines version in the getting started documentation link in the CSV file
OPENSHIFT_PIPELINES_MINOR_VERSION=${CURRENT_VERSION%.*}
sed -i 's/OPENSHIFT_PIPELINES_MINOR_VERSION/'"$OPENSHIFT_PIPELINES_MINOR_VERSION"'/g' .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

yq --inplace ".metadata.annotations[\"features.operators.openshift.io/cnf\"] = \"false\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
yq --inplace ".metadata.annotations[\"features.operators.openshift.io/cni\"] = \"false\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
yq --inplace ".metadata.annotations[\"features.operators.openshift.io/csi\"] = \"false\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

# For making sure any patches apply correctly on operator based containers
# cp -fR ./distgit/containers/openshift-pipelines-operator/kodata ./distgit/containers/openshift-pipelines-operator-proxy
# cp -fR ./distgit/containers/openshift-pipelines-operator/kodata ./distgit/containers/openshift-pipelines-operator-webhook

# remove maxOpenShiftVersion from properties.yaml
# TODO: this change should be updated in upstream operator code
yq --inplace 'del(.properties[] | select(.type == "olm.maxOpenShiftVersion"))' \
    .konflux/olm-catalog/bundle/metadata/properties.yaml

# update OCP minimum verson
sed -i -E 's%LABEL com.redhat.openshift.versions=".*%LABEL com.redhat.openshift.versions="'v${MIN_OPENSHIFT_VERSION}'"%' \
    .konflux/dockerfiles/bundle.Dockerfile

# update channels in operator bundle dockerfile
sed -i -E 's%LABEL operators.operatorframework.io.bundle.channels.v1=".*%LABEL operators.operatorframework.io.bundle.channels.v1="'latest,${CHANNEL_NAME}'"%' \
    .konflux/dockerfiles/bundle.Dockerfile

