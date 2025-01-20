#!/usr/bin/env bash
# Update images from project.yaml to "generated" files

LENGTH=$(yq e '.images | length' project.yaml)

KONFLUX_TENANT_IMAGE_REPO='redhat-user-workloads\/tekton-ecosystem-tenant'
RELEASE_IMAGE_REPO=openshift-pipeline

for i in $(seq 0 $((${LENGTH}-1))); do
    NAME=$(yq e ".images.${i}.name" project.yaml)
    REFERENCE=$(yq e ".images.${i}.value" project.yaml)

    if [[ $REFERENCE == *${KONFLUX_TENANT_IMAGE_REPO}* ]]; then
       REFERENCE=$(echo $REFERENCE | sed -e "s/$KONFLUX_TENANT_IMAGE_REPO/$RELEASE_IMAGE_REPO/" -e 's/\(.*\)\//\1-/')
    fi
    echo "${NAME}: ${REFERENCE}"

    yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].env[] | select(.name == \"${NAME}\") | .value) = \"${REFERENCE}\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
    yq eval --inplace "(.spec.relatedImages[] | select(.name == \"${NAME}\") | .image) = \"${REFERENCE}\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
done

# Operator's specifics
OPERATOR_REFERENCE=$(yq e '.images[] | select(.name == "OPENSHIFT_PIPELINES_OPERATOR_LIFECYCLE") | .value' project.yaml)
WEBHOOK_REFERENCE=$(yq e '.images[] | select(.name == "TEKTON_OPERATOR_WEBHOOK") | .value' project.yaml)
yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].image) = \"${OPERATOR_REFERENCE}\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"tekton-operator-webhook\")| .spec.template.spec.containers[].image) = \"${WEBHOOK_REFERENCE}\"" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
