# FIXME Long term, use a better image
FROM fedora:35

# FIXME: we don't need to set this HOME env variable
ENV HOME=/go/src/github.com/openshift-pipelines/operator/ \
    USER_UID=1001 \
    USER_NAME=generatetasks


# Maybe remove this and use packages at some points
RUN curl -L https://go.dev/dl/go1.20.10.linux-amd64.tar.gz | tar -C /usr/local -xzf -
ENV PATH=$PATH:/usr/local/go/bin

ARG TKN_VERSION=0.32.0
RUN ARCH=$(uname -m) \
    OS=$(uname) \
    && curl -L https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_${OS}_${ARCH}.tar.gz | tar zxf - -C /usr/local/bin

ARG OC_VERSION=4.13.9
RUN ARCH=$(uname -m) \
    OS=$(uname | tr '[:upper:]' '[:lower:]') \
    && echo https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/${OC_VERSION}/openshift-client-${OS}.tar.gz \
    && curl -L https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/${OC_VERSION}/openshift-client-${OS}.tar.gz | tar zxf - -C /usr/local/bin

RUN dnf install -y jq make diffutils which git gcc openssl findutils tree podman skopeo && rm -rf /var/cache/yum /var/cache/dnf

WORKDIR ${HOME}
ADD . .
COPY hack/images/e2e/bin /usr/local/bin
RUN  /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}
