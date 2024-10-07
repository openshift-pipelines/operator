#!/usr/bin/env bash
# Update images from image-mapping.yaml to "generated" files

LENGTH=$(yq e '.images | length' image-mapping.yaml)

for i in $(seq 0 $((${LENGTH}-1))); do
    NAME=$(yq e ".images.${i}.name" image-mapping.yaml)
    REFERENCE=$(yq e ".images.${i}.value" image-mapping.yaml)    

    echo "${NAME}: ${REFERENCE}"

    yq eval --inplace "(.spec.install.spec.deployments[] | select(.name == \"openshift-pipelines-operator\")| .spec.template.spec.containers[].env[] | select(.name == \"${NAME}\") | .value) = \"${REFERENCE}\"" openshift/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
    yq eval --inplace "(.spec.relatedImages[] | select(.name == \"${NAME}\") | .image) = \"${REFERENCE}\"" openshift/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml
done
