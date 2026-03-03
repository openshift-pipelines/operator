#!/usr/bin/env bash
# Update images from project.yaml to "generated" files
TAG=${1:-"devel"}
TARGET_REGISTRY="quay.io/openshift-pipeline"
LENGTH=$(yq e '.images | length' project.yaml)


function ensure_mirror() {
    input=$1

    SOURCE_PATTEN="quay.io/.*/(.*@sha256:.+)"
    TARGET_PATTEN="${TARGET_REGISTRY}/\1"
    output=$(echo "$input" | sed -E "s|$SOURCE_PATTEN|$TARGET_PATTEN|g")


     if [ $output == $input ]; then
      echo -e "\e[33m Image ${input} is already in the target registry, skipping \e[0m" >&2
      return 0
     fi

     # Check if the image exists in the target registry
    skopeo inspect --raw docker://${output} > /dev/null 2>&1
     if [ $? -ne 0 ]; then
         echo -e "\e[33m Image ${output} does not exist, Trying to mirror \e[0m" >&2
         sha=${output/*@sha256:/}
         new_image=${output/@sha256:*/}
         tags=("$TAG" "$sha")
         for tag in "${tags[@]}"; do
           echo "copying the image from $input to $new_image with tag $tag and preserving digests"
           skopeo copy docker://"$input" docker://"$new_image:$tag" --all --preserve-digests
         done

         skopeo copy --all docker://${input} docker://${output} > /dev/null 2>&1
         if [ $? -ne 0 ]; then
              echo -e "\e[31m Failed to mirror image ${input} to ${output} \e[0m" >&2
              return 1
          else
              echo "Successfully mirrored image ${input} to ${output}"
          fi
     fi

}
for i in $(seq 0 $((${LENGTH}-1))); do
    ensure_mirror "$(yq e ".images.${i}.value" project.yaml)"
done

