ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.22
ARG RUNTIME=registry.redhat.io/ubi8/ubi:latest@sha256:bf6868a6f7ca34ea53d8b0ba01cbcee5af44d359732be84e3d1185d4aecb2a8e

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
# COPY patches patches/
# RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-webhook \
    ./cmd/openshift/webhook

FROM $RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator-webhook \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-webhook ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/webhook/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-operator-webhook-rhel8-container" \
      name="openshift-pipelines/pipelines-operator-webhook-rhel8" \
      version="1.14.6" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.14::el8" \
      summary="Red Hat OpenShift Pipelines Operator Webhook" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Webhook" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Webhook" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator Webhook" \
      io.openshift.tags="operator,tekton,openshift,webhook"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-webhook"]
