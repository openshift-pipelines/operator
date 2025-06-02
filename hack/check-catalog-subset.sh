#!/bin/bash

set -e
# set -x # Uncomment for debugging

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to run this script."
    exit 1
fi

versions=("v4.15" "v4.16" "v4.17" "v4.18")
KONFLUX_OLM_INDEX_DIR=".konflux/olm-catalog/index"
RENDERED_INDEX_DIR="tmp"

for version in "${versions[@]}"; do
    echo "---------------------------------------------------------------------"
    echo "Checking version: ${version}"
    echo "---------------------------------------------------------------------"

    catalog_template_file="${KONFLUX_OLM_INDEX_DIR}/${version}/catalog-template.json"
    rendered_index_file="${RENDERED_INDEX_DIR}/target-index-${version}.json"

    # Check if files exist
    if [ ! -f "${catalog_template_file}" ]; then
        echo "ERROR: Catalog template file not found: ${catalog_template_file}"
        continue
    fi
    if [ ! -f "${rendered_index_file}" ]; then
        echo "ERROR: Rendered index file not found: ${rendered_index_file}"
        continue
    fi

    # --- Extract from catalog-template.json ---
    template_main_pkg_name=$(jq -r '.entries[] | select(.schema == "olm.package") | .name' "${catalog_template_file}")
    # Get all bundle names, sort them, and ensure uniqueness
    template_bundle_names=$(jq -r '.entries[] | select(.schema == "olm.bundle") | .name' "${catalog_template_file}" | sort -u)

    echo "Catalog Template File: ${catalog_template_file}"
    if [ -z "$template_main_pkg_name" ]; then
        echo "  No main package (olm.package) found in template."
    else
        echo "  Main Package (olm.package): ${template_main_pkg_name}"
    fi
    echo "  Bundle Names (olm.bundle) from template:"
    if [ -z "$template_bundle_names" ]; then
        echo "    No bundles found in template."
    else
        echo "${template_bundle_names}" | sed 's/^/    /' # Indent for readability
    fi
    echo

    # --- Extract from rendered-index.json ---
    # Rendered index is newline-delimited JSON.
    # Get all package names, sort them, and ensure uniqueness
    rendered_pkg_names=$(jq -r 'select(.schema == "olm.package" and .name == "openshift-pipelines-operator-rh") | .name' "${rendered_index_file}" | sort -u)
    # Get all bundle names, sort them, and ensure uniqueness
    rendered_bundle_names=$(jq -r 'select(.schema == "olm.bundle" and .package == "openshift-pipelines-operator-rh") | .name' "${rendered_index_file}" | sort -u)


    echo "Rendered Index File: ${rendered_index_file}"
    echo "  Package Name (olm.package) from rendered index (filtered for 'openshift-pipelines-operator-rh'):"
    if [ -z "$rendered_pkg_names" ]; then
        echo "    'openshift-pipelines-operator-rh' package NOT FOUND in rendered index."
    else
        echo "${rendered_pkg_names}" | sed 's/^/    /'
    fi
    echo "  Bundle Names (olm.bundle) from rendered index (for 'openshift-pipelines-operator-rh'):"
    if [ -z "$rendered_bundle_names" ]; then
        echo "    No bundles found in rendered index for 'openshift-pipelines-operator-rh'."
    else
        echo "${rendered_bundle_names}" | sed 's/^/    /'
    fi
    echo

    # --- Comparisons ---
    echo "--- Comparison Results for ${version} ---"

    # 1. Check main package
    if [ -n "$template_main_pkg_name" ]; then
        if echo "${rendered_pkg_names}" | grep -Fxq "${template_main_pkg_name}"; then
            echo "  [OK] Main package '${template_main_pkg_name}' from template FOUND in rendered index."
        else
            echo "  [MISSING] Main package '${template_main_pkg_name}' from template NOT FOUND in rendered index."
        fi
    fi

    # 2. Check bundles from template against rendered
    echo "  Bundles from template status in rendered index:"
    if [ -z "$template_bundle_names" ]; then
        echo "    No bundles in template to check."
    else
        all_template_bundles_found=true
        while IFS= read -r bundle_name; do
            if echo "${rendered_bundle_names}" | grep -Fxq "${bundle_name}"; then
                echo "    [OK] Template bundle '${bundle_name}' FOUND in rendered index."
            else
                echo "    [MISSING] Template bundle '${bundle_name}' NOT FOUND in rendered index."
                all_template_bundles_found=false
            fi
        done <<< "${template_bundle_names}"
        if $all_template_bundles_found && [ -n "$template_bundle_names" ]; then
             echo "    All bundles from template are present in the rendered index."
        fi
    fi
    echo

    # 3. Diff: Bundles in template BUT NOT in rendered (already covered by the above MISSING messages, but can be summarized)
    # Using comm: requires sorted lists
    bundles_only_in_template=$(comm -23 <(echo "${template_bundle_names}") <(echo "${rendered_bundle_names}"))
    if [ -n "$bundles_only_in_template" ]; then
        echo "  [DIFF] Bundles in '${catalog_template_file}' BUT NOT in '${rendered_index_file}' (for 'openshift-pipelines-operator-rh'):"
        echo "${bundles_only_in_template}" | sed 's/^/    /'
    else
        echo "  [INFO] All bundles from template are accounted for in the rendered index (for 'openshift-pipelines-operator-rh', or template has no bundles)."
    fi
    echo

    # 4. Diff: Bundles in rendered BUT NOT in template
    bundles_only_in_rendered=$(comm -13 <(echo "${template_bundle_names}") <(echo "${rendered_bundle_names}"))
    if [ -n "$bundles_only_in_rendered" ]; then
        echo "  [DIFF] Bundles in '${rendered_index_file}' (for 'openshift-pipelines-operator-rh') BUT NOT in '${catalog_template_file}':"
        echo "${bundles_only_in_rendered}" | sed 's/^/    /'

        echo "  [UPDATE] Attempting to add these missing bundles to '${catalog_template_file}'..."
        temp_catalog_output=$(mktemp)
        cp "${catalog_template_file}" "${temp_catalog_output}"
        update_successful=true

        while IFS= read -r bundle_name_to_add; do
            # Extract only schema, name, and image for the new bundle entry from the rendered index
            # Output must be compact JSON for --argjson
            bundle_json_to_add=$(jq -c --arg bname "$bundle_name_to_add" \
                'select(.schema == "olm.bundle" and .package == "openshift-pipelines-operator-rh" and .name == $bname) | {schema: .schema, name: .name, image: .image}' \
                "${rendered_index_file}")

            if [ -z "$bundle_json_to_add" ] || [ "$bundle_json_to_add" == "null" ]; then
                echo "    [WARN] Could not find specified fields (schema, name, image) for bundle '${bundle_name_to_add}' in '${rendered_index_file}'. Skipping this bundle."
                update_successful=false
                continue
            fi

            # Use jq to add this bundle to the .entries array of the temp catalog file
            jq --argjson new_entry "$bundle_json_to_add" '.entries += [$new_entry]' "${temp_catalog_output}" > "${temp_catalog_output}.tmp" 
            if [ $? -eq 0 ]; then
                mv "${temp_catalog_output}.tmp" "${temp_catalog_output}"
                echo "    Added bundle to temporary file: ${bundle_name_to_add}"
            else
                echo "    [ERROR] Failed to add bundle '${bundle_name_to_add}' to temporary file using jq. Skipping this bundle."
                update_successful=false
                rm -f "${temp_catalog_output}.tmp"
            fi
        done <<< "${bundles_only_in_rendered}"

        if $update_successful && [ -s "${temp_catalog_output}" ]; then
            # Pretty-print JSON from temp file to the original catalog file
            jq '.' "${temp_catalog_output}" > "${catalog_template_file}"
            if [ $? -eq 0 ]; then
                echo "  SUCCESS: Updated '${catalog_template_file}' with new bundles."
            else
                echo "  [ERROR] Failed to write updated and pretty-printed JSON to '${catalog_template_file}'. Original file might be unchanged or corrupted if temp file was moved manually."
            fi
        elif [ -s "${temp_catalog_output}" ]; then # update_successful is false but temp file exists
            echo "  [WARN] Some errors occurred during bundle processing. '${catalog_template_file}' was NOT updated. See warnings above. Temporary file at ${temp_catalog_output} may contain partial changes."
        else # temp_catalog_output is empty or does not exist, likely all bundles failed or no bundles to add that were processable
             echo "  [INFO] No processable bundles were added. '${catalog_template_file}' remains unchanged."
        fi
        # Clean up temp file if it wasn't moved or if it was for a failed operation but we don't want to keep it
        if [ -f "${temp_catalog_output}" ]; then # only remove if it still exists
             rm "${temp_catalog_output}"
        fi

    else
        echo "  [INFO] No additional bundles found in rendered index (for 'openshift-pipelines-operator-rh') compared to template (or rendered index has no relevant bundles). '${catalog_template_file}' is already up-to-date."
    fi
    echo
done

echo "---------------------------------------------------------------------"
echo "Script finished."
echo "---------------------------------------------------------------------" 