FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as base 
FROM scratch

COPY .konflux/olm-catalog/bundle/kodata /kodata 
COPY .konflux/olm-catalog/bundle/manifests /manifests
COPY .konflux/olm-catalog/bundle/metadata/annotations.yaml /metadata/annotations.yaml

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=serverless-operator
LABEL operators.operatorframework.io.bundle.channel.default.v1="pipelines-1.20"
LABEL operators.operatorframework.io.bundle.channels.v1="pipelines-1.20"

LABEL \
      com.redhat.component="openshift-pipelines-operator-bundle-container" \
      name="openshift-pipelines/pipelines-operator-bundle-container" \
      version="1.20.3" \ 
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
      url="https://access.redhat.com/containers/#/registry.access.redhat.com/ubi9-minimal/images/9.4-1227.1725849298" \
      release="1227.1725849298"

USER 65532
