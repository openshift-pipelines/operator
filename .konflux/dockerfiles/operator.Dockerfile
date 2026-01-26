ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.22
ARG RUNTIME=registry.redhat.io/ubi8/ubi:latest@sha256:a7e3d45d7ab598aefed9e2691ad9c368bb6b2db06f4cd4473d32eabfd0078519

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
# COPY patches patches/
# RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags disable_gcp -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator \
    ./cmd/openshift/operator

FROM $RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/operator/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-rhel8-operator-container" \
      name="openshift-pipelines/pipelines-rhel8-operator" \
      version="1.14.6" \
      summary="Red Hat OpenShift Pipelines Operator" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator" \
      io.openshift.tags="operator,tekton,openshift" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.14::el8"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]