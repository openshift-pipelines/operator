ARG GO_BUILDER=registry.access.redhat.com/hi/go:1.27-fips-builder@sha256:c4e5e6abdbbd3b731e71c8ad52a98630373fd2f47861877313420f0c8bafc268
ARG UBI_RUNTIME=registry.access.redhat.com/hi/go:1.27@sha256:446970d155b61d40c571346f4a7eb4e06b6ce9ea7655f337e2a68749c32326a9

FROM $GO_BUILDER as builder

WORKDIR /go/src/github.com/tektoncd/operator
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN go build -tags strictfipsruntime -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -o /tmp/openshift-pipelines-operator-proxy \
    ./cmd/openshift/proxy-webhook

FROM $UBI_RUNTIME

ENV OPERATOR_PROXY=/usr/local/bin/openshift-pipelines-operator-proxy \
    KO_DATA_PATH=/kodata

COPY --from=builder /tmp/openshift-pipelines-operator-proxy ${OPERATOR_PROXY}
COPY head ${KO_DATA_PATH}/HEAD

LABEL \
    com.redhat.component="openshift-pipelines-operator-proxy-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:next::el9" \
    description="Red Hat OpenShift Pipelines operator proxy" \
    io.k8s.description="Red Hat OpenShift Pipelines operator proxy" \
    io.k8s.display-name="Red Hat OpenShift Pipelines operator proxy" \
    io.openshift.tags="tekton,openshift,operator,proxy" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-operator-proxy-rhel9" \
    summary="Red Hat OpenShift Pipelines operator proxy" \
    version="next"

USER 65532:65532
ENTRYPOINT ["/usr/local/bin/openshift-pipelines-operator-proxy"]
