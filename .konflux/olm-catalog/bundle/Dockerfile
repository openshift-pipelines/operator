ARG RUNTIME=registry.access.redhat.com/ubi8/ubi-minimal@sha256:fba1e7fb1f50cd7b021c8379f207fb744b00ff55c7f539f15b40709a38cb4cde

FROM $RUNTIME as base
FROM scratch

COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY .konflux/olm-catalog/bundle/manifests /manifests
COPY .konflux/olm-catalog/bundle/metadata/annotations.yaml /metadata/annotations.yaml

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=openshift-pipelines-operator-rh
LABEL operators.operatorframework.io.bundle.channel.default.v1="pipelines-1.14"
LABEL operators.operatorframework.io.bundle.channels.v1="pipelines-1.14"

LABEL \
      com.redhat.component="openshift-pipelines-operator-bundle-container" \
      name="openshift-pipelines/pipelines-operator-bundle" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.14::el8" \
      version="1.14.x" \
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
      release="Openshift Pipelines 1.14.6" \
      url="https://access.redhat.com/containers/#/registry.access.redhat.com/ubi9-minimal/images/9.4-1227.1725849298"

USER 65532
