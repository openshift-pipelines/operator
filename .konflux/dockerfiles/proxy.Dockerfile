arg go_builder=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.22
arg runtime=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:c0e70387664f30cd9cf2795b547e4a9a51002c44a4a86aa9335ab030134bf392

from $go_builder as builder

workdir /go/src/github.com/tektoncd/operator
copy upstream .
# fixme: handle patches (maybe ? probably not needed though)
# copy patches patches/
# run set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
# env changeset_rev=$ci_operator_upstream_commit
env godebug="http2server=0"
run go build -ldflags="-X 'knative.dev/pkg/changeset.rev=${changeset_rev:0:7}'" -mod=vendor -o /tmp/openshift-pipelines-operator-proxy \
    ./cmd/openshift/proxy-webhook
# RUN /bin/sh -c 'echo $CI_PIPELINE_UPSTREAM_COMMIT > /tmp/HEAD'

FROM $RUNTIME

ENV OPERATOR_PROXY=/usr/local/bin/openshift-pipelines-operator-proxy \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-proxy ${OPERATOR_PROXY}
# COPY --from=builder /tmp/HEAD ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-operator-proxy-rhel8-container" \
      name="openshift-pipelines/pipelines-operator-proxy-rhel8" \
      version="${CI_CONTAINER_VERSION}" \
      summary="Red Hat OpenShift Pipelines Operator Proxy" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Proxy" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Proxy" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator Proxy" \
      io.openshift.tags="operator,tekton,openshift,proxy"

RUN microdnf install -y shadow-utils
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-proxy"]
