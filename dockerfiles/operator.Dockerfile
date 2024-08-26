# FIXME: this needs to be generated
# FROM openshift/golang-builder:rhel_8_golang_1.22 AS builder
# FROM brew.registry.redhat.io/rh-osbs/openshift-golang-builder:rhel_8_golang_1.22 AS builder
FROM quay.io/projectquay/golang:1.23 AS builder

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

FROM registry.redhat.io/ubi8/ubi-minimal:latest

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/operator/kodata/ ${KO_DATA_PATH}/
# COPY --from=builder /tmp/HEAD ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-rhel8-operator-container" \
      name="openshift-pipelines/pipelines-rhel8-operator" \
      version="1.16.0" \
      summary="Red Hat OpenShift Pipelines Operator" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator"

RUN microdnf install -y shadow-utils
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
