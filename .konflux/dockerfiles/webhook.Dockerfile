ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25.5-1769430014@sha256:359dd4c6c4255b3f7bce4dc15ffa5a9aa65a401f819048466fa91baa8244a793
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:ecd4751c45e076b4e1e8d37ac0b1b9c7271930c094d1bcc5e6a4d6954c6b2289

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
      name="openshift-pipelines/pipelines-operator-webhook-rhel9" \
      version="next" \
      summary="Red Hat OpenShift Pipelines Operator Webhook" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Operator Webhook" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Operator Webhook" \
      io.k8s.description="Red Hat OpenShift Pipelines Operator Webhook" \
      io.openshift.tags="operator,tekton,openshift,webhook"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-webhook"]
