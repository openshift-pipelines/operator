ARG RUNTIME=registry.access.redhat.com/ubi8/ubi-minimal@sha256:58b1dc5427b699255a73475f5e96e9f658f49214e5bd56d03c534fa87980efb1

FROM $RUNTIME as base
FROM scratch

COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY .konflux/olm-catalog/bundle/manifests /manifests
COPY .konflux/olm-catalog/bundle/metadata/annotations.yaml /metadata/annotations.yaml

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=openshift-pipelines-operator-rh
LABEL operators.operatorframework.io.bundle.channel.default.v1="pipelines-1.16"
LABEL operators.operatorframework.io.bundle.channels.v1="pipelines-1.16"

LABEL \
      com.redhat.component="openshift-pipelines-operator-bundle-container" \
      name="openshift-pipelines/pipelines-operator-bundle-container" \
      version="1.16.4" \
      summary="Red Hat OpenShift Pipelines Operator Bundle" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Bundle" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Bundle" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator Bundle" \
      com.redhat.delivery.operator.bundle=true \
      com.redhat.delivery.backport=false \
      io.openshift.tags="pipelines,tekton,openshift" \
      vendor="Red Hat, Inc." \
      distribution-scope="public" \
      release="Openshift Pipelines 1.16.4" \
      url="https://access.redhat.com/containers/#/registry.access.redhat.com/ubi9-minimal/images/9.4-1227.1725849298"

USER 65532
