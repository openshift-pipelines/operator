#!/usr/bin/env bash

# Copyright 2020 The Tekton Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

source $(git rev-parse --show-toplevel)/vendor/github.com/tektoncd/plumbing/scripts/library.sh

cd ${REPO_ROOT_DIR}

BRANCH=main

# Parse flags to determine any we should pass to dep.
GO_GET=0
while [[ $# -ne 0 ]]; do
  parameter=$1
  case ${parameter} in
    --upgrade) GO_GET=1 ;;
    *) abort "unknown option ${parameter}" ;;
  esac
  shift
done
readonly GO_GET

if (( GO_GET )); then
    # We'll use the commit to fetch information from it
    COMMIT=$(git ls-remote https://github.com/tektoncd/operator refs/heads/${BRANCH} | awk '{print $1 }')
    echo "Updating dependency based of tektoncd/operator (${COMMIT})"

    UPSTREAMGOMOD=$(mktemp /tmp/tektoncd-operator-${COMMIT}-gomod.XXXXXXXX)
    trap "rm -f ${UPSTREAMGOMOD}" EXIT

    curl -L https://github.com/tektoncd/operator/raw/${COMMIT}/go.mod > ${UPSTREAMGOMOD}

    go get -d github.com/tektoncd/operator@${COMMIT}
    
    # Make sure we have the same "replace" as operator upstream
    go run -mod=mod  ./cmd/tool mod ${UPSTREAMGOMOD} go.mod
fi

# Prune modules.
go mod tidy
go mod vendor

# Applying patches
if [[ -d hack/patches ]];then
    for f in hack/patches/*.patch;do
        [[ -f ${f} ]] || continue
        # Apply patches but do not commit
        git apply ${f}
    done
fi

