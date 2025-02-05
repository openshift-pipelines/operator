ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.23
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:3902bab19972cd054fd08b2a4e08612ae7e68861ee5d9a5cf22d828f27e2f479

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
# FIXME: handle patches (maybe ? probably not needed though)
# COPY patches patches/
# RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
# ENV CHANGESET_REV=$CI_OPERATOR_UPSTREAM_COMMIT
ENV GODEBUG="http2server=0"
RUN go build -tags disable_gcp -ldflags="-X 'knative.dev/pkg/changeset.rev=${CHANGESET_REV:0:7}'" -mod=vendor -o /tmp/openshift-pipelines-operator \
    ./cmd/openshift/operator
# RUN /bin/sh -c 'echo $CI_OPERATOR_UPSTREAM_COMMIT > /tmp/HEAD'

FROM $RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/operator/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata

LABEL \
      com.redhat.component="openshift-pipelines-rhel8-operator-container" \
      name="openshift-pipelines/pipelines-rhel8-operator" \
      version="1.16.0" \
      summary="Red Hat OpenShift Pipelines Operator" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator" \
      io.openshift.tags="operator,tekton,openshift"

RUN microdnf install -y shadow-utils
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
