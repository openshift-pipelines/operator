#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This script is used to run e2e tests in CI.
# It is assumed that the script is run from the root of the repository.

go env
# vendir sync

# Make sure openshift internal registry is properly setup…
env | grep KUBECONFIG
env
oc login -u kubeadmin -p $(cat $KUBEADMIN_PASSWORD_FILE) --insecure-skip-tls-verify=true
oc whoami -t
oc project

set -x
# … so that we can use `ko apply` using it.
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
sleep 10
oc wait configs.imageregistry.operator.openshift.io/cluster --for condition=Available --timeout=300s
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' >pull-secret.json
# Login (write to DOCKER_CONFIG_JSON) as well as in cluster
oc registry login --registry="${HOST}" --auth-basic="kubeadmin:$(cat $KUBEADMIN_PASSWORD_FILE)"
oc registry login --registry="${HOST}" --auth-basic="kubeadmin:$(cat $KUBEADMIN_PASSWORD_FILE)" --to=pull-secret.json
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=pull-secret.json
sleep 10

# Wait for machine to be up-to-date (machineconfigpool)
oc wait machineconfigpool/master --for condition=updated --timeout=600s
oc wait machineconfigpool/worker --for condition=updated --timeout=600s

podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST

export KO_DOCKER_REPO=${HOST}/default
# Deploy the upstream operator
(cd upstream && make KO_FLAGS=--insecure-registry TARGET=openshift apply)

# Now wait for the operator to be up and running
oc wait tektonconfig/config --for condition=Ready
set +x

oc get -n openshift-pipelines pods -o yaml

# Force it to fail to check something
exit 1
