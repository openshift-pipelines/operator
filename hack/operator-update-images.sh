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
    # Third-party images (e.g. registry.redhat.io) are used as-is: they aren't
    # mirrored, and skopeo can't inspect them here without registry credentials.
    if [[ ! "$input" =~ ^quay\.io/ ]]; then
        echo "$input"
        return 0
    fi
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

# Third-party images pulled directly by operands: add (or update) them in relatedImages
LENGTH=$(yq e '.extraRelatedImages | length' project.yaml)
for i in $(seq 0 $((${LENGTH}-1))); do
    NAME=$(yq e ".extraRelatedImages.${i}.name" project.yaml)
    REFERENCE=$(yq e ".extraRelatedImages.${i}.value" project.yaml)
    echo "${NAME}: ${REFERENCE} (relatedImages only)"
    if [ "$(yq e "[.spec.relatedImages[] | select(.name == \"${NAME}\")] | length" $CSV_FILE)" -eq 0 ]; then
      yq eval --inplace ".spec.relatedImages += [{\"image\": \"${REFERENCE}\", \"name\": \"${NAME}\"}]" $CSV_FILE
    else
      yq eval --inplace "(.spec.relatedImages[] | select(.name == \"${NAME}\") | .image) = \"${REFERENCE}\"" $CSV_FILE
    fi
done

# Operator's specifics
REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "OPENSHIFT_PIPELINES_OPERATOR_LIFECYCLE") | .value' project.yaml)")
if [ $? -ne 1 ]; then
  yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE
  # Update containerImage annotation with the full SHA
  yq eval --inplace "(.metadata.annotations.containerImage) = \"${REFERENCE}\"" $CSV_FILE
fi

REFERENCE=$(update_image_reference "$(yq e '.images[] | select(.name == "TEKTON_OPERATOR_WEBHOOK") | .value' project.yaml)")
if [ $? -ne 1 ]; then
  yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"tekton-operator-webhook\")| .spec.template.spec.containers[].image) = \"${REFERENCE}\"" $CSV_FILE
fi
