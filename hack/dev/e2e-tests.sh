#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This script is used to run e2e tests in CI.
# It is assumed that the script is run from the root of the repository.

go env
# vendir sync

# Deploy the upstream operator
(cd upstream && make TARGET=openshift apply)

# Force it to fail to check something
exit 1
