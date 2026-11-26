ARG GO_BUILDER=registry.access.redhat.com/ubi10/go-toolset:latest@sha256:b9f867772f02ef0c8167b1ac327b615c9c6b06be16f5a42ea322597633d1d25e
ARG UBI_RUNTIME=registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:d63890a635f8f19177bce1775f74f587a47f4456844f1392456c4e3673a48753

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-webhook \
    ./cmd/openshift/webhook

FROM $UBI_RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator-webhook \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-webhook ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/webhook/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
    com.redhat.component="openshift-pipelines-operator-webhook-rhel10-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:nightly::el10" \
    description="Red Hat OpenShift Pipelines operator webhook" \
    io.k8s.description="Red Hat OpenShift Pipelines operator webhook" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator webhook" \
    io.openshift.tags="tekton,openshift,operator,webhook" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-operator-webhook-rhel10" \
    summary="Red Hat OpenShift Pipelines operator webhook" \
    version="nightly"

RUN microdnf install -y shadow-utils && \
     groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-webhook"]
