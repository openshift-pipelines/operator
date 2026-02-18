ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1771417345@sha256:799cc027d5ad58cdc156b65286eb6389993ec14c496cf748c09834b7251e78dc
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:759f5f42d9d6ce2a705e290b7fc549e2d2cd39312c4fa345f93c02e4abb8da95

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-webhook \
    ./cmd/openshift/webhook

FROM $RUNTIME

ENV OPERATOR=/usr/local/bin/openshift-pipelines-operator-webhook \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-webhook ${OPERATOR}
COPY --from=builder /go/src/github.com/tektoncd/operator/cmd/openshift/webhook/kodata/ ${KO_DATA_PATH}/
COPY .konflux/olm-catalog/bundle/kodata /kodata
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
      com.redhat.component="openshift-pipelines-operator-webhook-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines operator webhook" \
      io.k8s.description="Red Hat OpenShift Pipelines operator webhook" \
      io.k8s.display-name="Red Hat OpenShift Pipelines operator webhook" \
      io.openshift.tags="tekton,openshift,operator,webhook" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-operator-webhook-rhel9" \
      summary="Red Hat OpenShift Pipelines operator webhook" \
      version="v1.22.0"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-webhook"]
