ARG GO_BUILDER=registry.redhat.io/ubi9/go-toolset:latest@sha256:23c7cb17e9c53a65f9ab01f2edf1a4e07c9a9dc2258ed63d69e06925e7cea381
ARG UBI_RUNTIME=registry.redhat.io/ubi9/ubi-minimal-pqc:latest@sha256:5e9a0970f73f4800445c3ce0ca0d6b7ea1a8c620b81e735d16432db09d6787bc

FROM $GO_BUILDER as builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-proxy \
    ./cmd/openshift/proxy-webhook

FROM $UBI_RUNTIME

ENV OPERATOR_PROXY=/usr/local/bin/openshift-pipelines-operator-proxy \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-proxy ${OPERATOR_PROXY}
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
    com.redhat.component="openshift-pipelines-operator-proxy-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.25::el9" \
    description="Red Hat OpenShift Pipelines operator proxy" \
    io.k8s.description="Red Hat OpenShift Pipelines operator proxy" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator proxy" \
    io.openshift.tags="tekton,openshift,operator,proxy" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-operator-proxy-rhel9" \
    summary="Red Hat OpenShift Pipelines operator proxy" \
    version="v1.25.0"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532
ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-proxy"]
