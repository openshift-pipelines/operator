FROM registry.redhat.io/openshift4/ose-operator-registry:v4.13 AS opm
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

COPY --from=opm /bin/opm /bin/opm

# Copy declarative config root into image at /configs
COPY .konflux/olm-catalog/index/configs /configs

# RUN /bin/opm init openshift-pipelines-operator --default-channel=latest --output yaml >> /configs/index.yaml
RUN /bin/opm render --skip-tls-verify -o yaml quay.io/redhat-user-workloads/tekton-ecosystem-tenant/operator-main/bundle@sha256:48405ceb706408f8bd2dcf05d081df8cad379c89f391a4e63505d81d1b46ed28 > /configs/nightly-bundle.yaml
RUN export BUNDLE_VERSION=$(cat /configs/nightly-bundle.yaml | grep 'name: openshift-pipelines-operator-rh' | awk '{print $2}') && \
    echo $BUNDLE_VERSION && \
    sed -i "s%name: \"openshift-pipelines-operator-rh.*\"%name: \"${BUNDLE_VERSION}\"%g" /configs/index.yaml && \
    cat /configs/index.yaml
RUN /bin/opm validate configs

# The base image is expected to contain
# /bin/opm (with a serve subcommand) and /bin/grpc_health_probe
FROM registry.redhat.io/openshift4/ose-operator-registry:latest

# Copy declarative config root into image at /configs
COPY --from=builder /configs /configs

# Set DC-specific label for the location of the DC root directory
# in the image
LABEL operators.operatorframework.io.index.configs.v1=/configs

# Configure the entrypoint and command
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs"]
