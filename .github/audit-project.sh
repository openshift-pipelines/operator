#!/usr/bin/bash

set -euo pipefail


function check_images() {
    context=${1}
    source_file="${PWD}/${2}"
    images_file="${PWD}/${3}"

    errors="$PWD/errors.txt"
    [[ -e "${errors}" ]] && rm "${errors}"
    [[ -d repos ]] && rm -r repos
    [[ -d images ]] && rm -r images
    mkdir repos
    mkdir images

    while read -r image; do
      echo "Checking ${image}"
      if [[ "${image}" != *"openshift-pipeline"* ]] && [[ "${image}" != *"tekton"* ]]; then
          echo "Skipping ${image}, not an openshift pipelines image"
          continue
      fi

      image_data=$(skopeo inspect --config "docker://${image}" || echo '{}')
      if [[ "${image_data}" == '{}' ]]; then
        grep -n "${image}" "${source_file}" | cut -d ':' -f1| while read -r line_no; do
            echo "::error file=${source_file},line=${line_no},title=Missing image in ${context}::Could not fetch ${image}"
        done

        echo "- Image ${image} not found" >> "${errors}"
        continue
      fi
      labels=$(echo "${image_data}" | jq '.config.Labels')
      repository=$(echo -n "${labels}" | jq -r '.["io.openshift.build.source-location"]')
      revision=$(echo -n "${labels}" | jq -r '.["io.openshift.build.commit.id"]')
      if [[ -z "${repository}" ]]; then
        echo "Unable to find source location for ${image}"
      else
        repository=$(echo "${repository}" | cut -d '/' -f 4- | tr '/' '_')
      fi
      echo "${revision}" >> "repos/${repository}"
      echo "${image}" >> "images/${revision}"
    done < "${images_file}"

    # Separate fetching errors from validation errors
    [[ -e "${errors}" ]] && echo -e "\n---\n" >> "${errors}"

    pushd repos
    trap "popd" RETURN
    for repo in *; do
      revisions="$(sort "${repo}"| uniq)"

      if [[ "$(echo "${revisions}" | wc -l)" -ne "1" ]]; then
        echo "## ${repo} has images from multiple revisions:" | tee -a "$errors"
        echo "${revisions}" | while read -r revision; do
          all_images=$(sort "../images/${revision}" | uniq)
          all_revisions_oneline=$(echo "${revisions}" | xargs)
          echo -e "### Revision ${revision}:" | tee -a "$errors"
          echo "${all_images}" | sed 's/^/- image `/g; s/$/`/g' | tee -a "${errors}"
          echo "${all_images}" | while read -r image; do
            grep -n "${image}" "${source_file}" | cut -d ':' -f1 | while read -r line_no; do
              echo "::warning file=${source_file},line=${line_no},title=Inconsistent source commits::repository: ${repo}, revision: ${revision}, images reference revisions: ${all_revisions_oneline}"
            done
          done
        done
      fi
    done

    if [[ -e "${errors}" ]]; then
      echo "# Errors detected in ${context}" | tee -a "${GITHUB_STEP_SUMMARY}"
      tee -a "${GITHUB_STEP_SUMMARY}" < "${errors}"
    fi
}

echo "::group:: Checking project.yaml"
yq eval '.images[].value' project.yaml | sort | uniq > images.txt
check_images "project.yaml" project.yaml images.txt
echo "::endgroup::"


echo "::group:: Checking Cluster Service Version"
yq eval '.spec.relatedImages[].image' .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml | sort | uniq > csv_images.txt
check_images "cluster service version" .konflux/olm-catalog/bundle/manifests/openshift-pipelines-operator-rh.clusterserviceversion.yaml csv_images.txt
echo "::endgroup::"

if [ -s "${GITHUB_STEP_SUMMARY}" ]; then
    exit 1
fi
