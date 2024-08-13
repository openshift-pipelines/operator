# use non-scratch parent image as dummy for https://issues.redhat.com/browse/KFLUXBUGS-10
FROM registry.redhat.io/ubi8/ubi-micro:latest
FROM scratch

COPY olm-catalog/serverless-operator/manifests /manifests
COPY olm-catalog/serverless-operator/metadata/annotations.yaml /metadata/annotations.yaml

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=serverless-operator
LABEL operators.operatorframework.io.bundle.channel.default.v1="latest"
LABEL operators.operatorframework.io.bundle.channels.v1="latest,pipelines-1.16"

LABEL \
      com.redhat.component="openshift-pipelines-operator-bundle-container" \
      name="openshift-pipelines/pipelines-operator-bundle-container" \
      version="${CI_CONTAINER_VERSION}" \
      summary="Red Hat OpenShift Pipelines Operator Bundle" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Bundle" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Bundle" \
      com.redhat.delivery.operator.bundle=true \
      com.redhat.delivery.backport=false

USER 65532
