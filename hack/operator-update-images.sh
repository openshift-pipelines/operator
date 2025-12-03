#!/usr/bin/env bash
# Update images from project.yaml to "generated" files
ENVIRONMENT=${1:-"devel"}
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

function update_image_reference() {
    SOURCE_PATTEN="quay.io/.*/(pipeline-)?(.*@sha256:.+)"
    TARGET_PATTEN="${TARGET_REGISTRY}/\2"
    input=$1
    output=$(echo "$input" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")


     # Check if the image exists in the target registry
    skopeo inspect --raw docker://${output} > /dev/null 2>&1
     if [ $? -ne 0 ]; then
         echo -e "\e[31m Image ${output} does not exist, skipping update \e[0m" >&2
         return 1
     fi
    echo "$output"
}
CSV_FILE=".konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml"
LENGTH=$(yq e '.images | length' project.yaml)
for i in $(seq 0 $((${LENGTH}-1))); do
    NAME=$(yq e ".images.${i}.name" project.yaml)
    REFERENCE=$(update_image_reference "$(yq e ".images.${i}.value" project.yaml)")
    if [ $? -ne 1 ]; then
      echo "${NAME}: ${REFERENCE}"

      yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].env[] | select(.name == \"${NAME}\") | .value) = \"${REFERENCE}\"" $CSV_FILE
      yq eval --inplace "(.spec.relatedImages[] | select(.name == \"${NAME}\") | .image) = \"${REFERENCE}\"" $CSV_FILE
    fi
done

# Operator's specifics
REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "OPENSHIFT_PIPELINES_OPERATOR_LIFECYCLE") | .value' project.yaml)")
if [ $? -ne 1 ]; then
  yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE
fi

REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "TEKTON_OPERATOR_WEBHOOK") | .value' project.yaml)")
if [ $? -ne 1 ]; then
  yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"tekton-operator-webhook\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE
fi