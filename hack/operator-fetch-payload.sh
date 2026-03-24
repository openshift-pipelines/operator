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
for binary in operator-sdk kustomize yq; do
    command -v $binary > /dev/null 2>&1 || { echo >&2 "$binary not installed, aborting..."; exit 1; }
done

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

# Remove label matchselector app
yq e -i 'del(.spec.install.spec.deployments[0].spec.selector.matchLabels.app)' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
yq e -i 'del(.metadata.annotations["createdAt"])' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml

# Add valid-subscription annotation
yq e -i '.metadata.annotations["operators.openshift.io/valid-subscription"] = "[\"OpenShift Container Platform\", \"OpenShift Platform Plus\"]"' \
   .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml


# Update VERSION env variable to use ${VERSION=}
yq e -i "(.spec.install.spec.deployments[] | select (.name == \"openshift-pipelines-operator\") | .spec.template.spec.containers[0].env[] | select (.name == \"VERSION\") | .value) = \"${CURRENT_VERSION}\"" \
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

