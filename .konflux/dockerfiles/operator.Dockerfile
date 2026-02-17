ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1771271449@sha256:4c0a6ea209ccc5028c45d3fd886dd0f51e52a8917bceea15c759a2bd2598836f
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal@sha256:c7d44146f826037f6873d99da479299b889473492d3c1ab8af86f08af04ec8a0 

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
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines operator operator" \
      io.k8s.description="Red Hat OpenShift Pipelines operator operator" \
      io.k8s.display-name="Red Hat OpenShift Pipelines operator operator" \
      io.openshift.tags="tekton,openshift,operator,operator" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-rhel9-operator" \
      summary="Red Hat OpenShift Pipelines operator operator" \
      version="v1.22.0"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator"]
