#!/bin/bash

# Use this script to update the Tekton Task Bundle references used in a Pipeline or a PipelineRun.
# Since the `main` branch of the operator is not onboarded to Konflux
# the Task bundle versions are not managed by Mintmaker so it is necessary
# to maintain the image versions manually. This script updates the task
# bundle references.
#
# !! It does not upgrade minor versions and it does not apply any migrations!!
#
# See also: https://konflux.pages.redhat.com/docs/users/troubleshooting/builds.html#manually-update-task-bundles

set -euo pipefail

function update_tekton_task_bundles() {
    FILES=$@

    # Determine the flavor of yq and adjust yq commands accordingly
    if [ -z "$(yq --version | grep mikefarah)" ]; then
       # Python yq
       YQ_FRAGMENT1='.. | select(type == "object" and has("resolver"))'
       YQ_FRAGMENT2='-r'
    else
       # mikefarah yq
       YQ_FRAGMENT1='... | select(has("resolver"))'
       YQ_FRAGMENT2=''
    fi

    # Find existing image references
    OLD_REFS="$(\
        yq "$YQ_FRAGMENT1 | .params // [] | .[] | select(.name == \"bundle\") | .value"  $FILES | \
        grep -v -- '---' | \
        sed 's/^"\(.*\)"$/\1/' | \
        sort -u \
    )"

    # Find updates for image references
    for old_ref in ${OLD_REFS}; do
        repo_tag="${old_ref%@*}"

        if [ -z "$(echo "${repo_tag}" | grep ':.\+' 2>/dev/null)" ]; then
            echo "WARNING: bundle ${repo_tag} does not include tag and cannot be automatically updated"
            continue
        fi

        new_digest="$(skopeo inspect --no-tags docker://${repo_tag} | yq $YQ_FRAGMENT2 '.Digest')"
        new_ref="${repo_tag}@${new_digest}"
        [[ $new_ref == $old_ref ]] && continue
        echo "New digest found! $new_ref"
        for file in $FILES; do
            sed -i -e "s!${old_ref}!${new_ref}!g" $file
        done
    done
}

update_tekton_task_bundles "$(git rev-parse --show-toplevel)/.tekton/**.y*ml"
