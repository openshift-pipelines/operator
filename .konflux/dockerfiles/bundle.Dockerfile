ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest

FROM $RUNTIME as base
FROM scratch

COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY .konflux/olm-catalog/bundle/manifests /manifests
COPY .konflux/olm-catalog/bundle/metadata/annotations.yaml /metadata/annotations.yaml

LABEL \
    com.redhat.component="openshift-pipelines-operator-bundle-container" \
    com.redhat.delivery.backport="false" \
    com.redhat.delivery.operator.bundle="true" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.15::el9" \
    description="Red Hat OpenShift Pipelines operator bundle" \
    distribution-scope="public" \
    io.k8s.description="Red Hat OpenShift Pipelines operator bundle" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator bundle" \
    io.openshift.tags="tekton,openshift,operator,bundle" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-operator-bundle" \
    operators.operatorframework.io.bundle.channel.default.v1="pipelines-1.15" \
    operators.operatorframework.io.bundle.channels.v1="pipelines-1.15" \
    operators.operatorframework.io.bundle.manifests.v1="manifests/" \
    operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
    operators.operatorframework.io.bundle.metadata.v1="metadata/" \
    operators.operatorframework.io.bundle.package.v1="openshift-pipelines-operator-rh" \
    release="Openshift Pipelines 1.15.3" \
    summary="Red Hat OpenShift Pipelines operator bundle" \
    url="https://access.redhat.com/containers/#/registry.access.redhat.com/ubi9-minimal/images/9.4-1227.1725849298" \
    vendor="Red Hat, Inc." \
    version="v1.15.5"

USER 65532
