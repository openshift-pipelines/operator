ARG GO_BUILDER=registry.redhat.io/ubi9/go-toolset:latest@sha256:a2ad457dc7525635613d2355037239ca9bf4374ba3b59961d1cdaa4d5f1af7d8
ARG UBI_RUNTIME=registry.redhat.io/ubi9/ubi-minimal-pqc:latest@sha256:c7fdcf2617a608d07f95fa01d8936fc8bf898096a60e5ebc432aae8ead50ea6c

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
    cpe="cpe:/a:redhat:openshift_pipelines:1.24::el9" \
    description="Red Hat OpenShift Pipelines operator operator" \
    io.k8s.description="Red Hat OpenShift Pipelines operator operator" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator operator" \
    io.openshift.tags="tekton,openshift,operator,operator" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-rhel9-operator" \
    summary="Red Hat OpenShift Pipelines operator operator" \
    version="v1.24.4"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
