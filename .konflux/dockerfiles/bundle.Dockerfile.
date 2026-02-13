FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as base 
FROM scratch

COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY .konflux/olm-catalog/bundle/manifests /manifests
COPY .konflux/olm-catalog/bundle/metadata/annotations.yaml /metadata/annotations.yaml

LABEL \
      com.redhat.component="openshift-pipelines-operator-bundle-container" \
      com.redhat.delivery.backport="false " \
      com.redhat.delivery.operator.bundle="true " \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines operator bundle" \
      distribution-scope="public" \
      io.k8s.description="Red Hat OpenShift Pipelines operator bundle" \
      io.k8s.display-name="Red Hat OpenShift Pipelines operator bundle" \
      io.openshift.tags="tekton,openshift,operator,bundle" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-operator-bundle" \
      operators.operatorframework.io.bundle.channel.default.v1="latest" \
      operators.operatorframework.io.bundle.channels.v1="latest,pipelines-1.22" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="serverless-operator" \
      release="1227.1725849298" \
      summary="Red Hat OpenShift Pipelines operator bundle" \
      url="https://access.redhat.com/containers/#/registry.access.redhat.com/ubi9-minimal/images/9.4-1227.1725849298" \
      vendor="Red Hat, Inc." \
      version="v1.22.0"


USER 65532
