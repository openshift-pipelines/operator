FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19

ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]

COPY .konflux/olm-catalog/index/v4.19/catalog/ /configs
RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]

# Core bundle labels.

LABEL \
      com.redhat.component="openshift-operator/pipelines-index-4.19-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines operator index-4.19" \
      io.k8s.description="Red Hat OpenShift Pipelines operator index-4.19" \
      io.k8s.display-name="Red Hat OpenShift Pipelines operator index-4.19" \
      io.openshift.tags="tekton,openshift,operator,index-4.19" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/operator/pipelines-index-4.19" \
      operators.operatorframework.io.bundle.channel.default.v1="latest" \
      operators.operatorframework.io.bundle.channels.v1="latest,pipelines-1.22" \
      operators.operatorframework.io.bundle.manifests.v1="manifests/" \
      operators.operatorframework.io.bundle.mediatype.v1="registry+v1" \
      operators.operatorframework.io.bundle.metadata.v1="metadata/" \
      operators.operatorframework.io.bundle.package.v1="openshift-pipelines-operator-rh" \
      operators.operatorframework.io.index.configs.v1="/configs" \
      operators.operatorframework.io.metrics.builder="operator-sdk-v1.37.0" \
      operators.operatorframework.io.metrics.mediatype.v1="metrics+v1" \
      summary="Red Hat OpenShift Pipelines operator index-4.19" \
      version="v1.22.0"


