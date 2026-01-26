ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:bb08f2300cb8d12a7eb91dddf28ea63692b3ec99e7f0fa71a1b300f2756ea829 

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags disable_gcp,strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator \
    ./cmd/openshift/operator

FROM $RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/operator/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-rhel9-operator-container" \
      name="openshift-pipelines/pipelines-rhel9-operator" \
      version="1.21.0" \
      summary="Red Hat OpenShift Pipelines Operator" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator" \
      io.openshift.tags="operator,tekton,openshift"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
