ARG GO_BUILDER=registry.access.redhat.com/ubi10/go-toolset:latest@sha256:be70aa468168f1ecd46e56d5f362e697243bcf9d3a2d98819597e43471a5d0e4
ARG UBI_RUNTIME=registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:ab67cd02caf8706e34a695a1432ebe965934f6128ec352a6c3f4048b43a4fb5e

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags disable_gcp,strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator \
    ./cmd/openshift/operator

FROM $UBI_RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/operator/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
    com.redhat.component="openshift-pipelines-rhel9-operator-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:nightly::el10" \
    description="Red Hat OpenShift Pipelines operator operator" \
    io.k8s.description="Red Hat OpenShift Pipelines operator operator" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator operator" \
    io.openshift.tags="tekton,openshift,operator,operator" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-rhel9-operator" \
    summary="Red Hat OpenShift Pipelines operator operator" \
    version="nightly"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
