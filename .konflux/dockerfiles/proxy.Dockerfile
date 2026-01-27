ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.23
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:bb08f2300cb8d12a7eb91dddf28ea63692b3ec99e7f0fa71a1b300f2756ea829 

FROM $GO_BUILDER as builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-proxy \
    ./cmd/openshift/proxy-webhook

FROM $RUNTIME

ENV OPERATOR_PROXY=/usr/local/bin/openshift-pipelines-operator-proxy \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-proxy ${OPERATOR_PROXY}
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-operator-proxy-rhel9-container" \
      name="openshift-pipelines/pipelines-operator-proxy-rhel9" \
      version="1.19.4" \
      summary="Red Hat OpenShift Pipelines Operator Proxy" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Proxy" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Proxy" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator Proxy" \
      io.openshift.tags="operator,tekton,openshift,proxy"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-proxy"]
