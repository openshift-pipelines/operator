#!/usr/bin/env bash
# Update images from project.yaml to "generated" files
TARGET_REGISTRY=${1:-"quay.io/openshift-pipeline"}
function update_image_reference() {
    SOURCE_PATTEN="quay.io/.*/(pipeline-)?(.*@sha256:.+)"
    TARGET_PATTEN="${TARGET_REGISTRY}/pipelines-\2"
    input=$1
    output=$(echo "$input" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")

     #Update Operator Image operator-operator to operator
     output=$(echo "$output" | sed -E "s/operator-operator-rhel9/rhel9-operator/g")

      echo "$output"
}
CSV_FILE=".konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml"
LENGTH=$(yq e '.images | length' project.yaml)
for i in $(seq 0 $((${LENGTH}-1))); do
    NAME=$(yq e ".images.${i}.name" project.yaml)
    REFERENCE=$(update_image_reference "$(yq e ".images.${i}.value" project.yaml)")
    echo "${NAME}: ${REFERENCE}"

    yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].env[] | select(.name == \"${NAME}\") | .value) = \"${REFERENCE}\"" $CSV_FILE
    yq eval --inplace "(.spec.relatedImages[] | select(.name == \"${NAME}\") | .image) = \"${REFERENCE}\"" $CSV_FILE
done
#
## Operator's specifics
REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "OPENSHIFT_PIPELINES_OPERATOR_LIFECYCLE") | .value' project.yaml)")
yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE

REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "TEKTON_OPERATOR_WEBHOOK") | .value' project.yaml)")
yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"tekton-operator-webhook\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE
