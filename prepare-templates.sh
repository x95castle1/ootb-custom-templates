#!/bin/bash

# Directory containing the YAML files
YAML_DIR="./ootb-templates-test"

SCRIPTING_BASE_IMAGE=$(kubectl get task -n tap-tasks kaniko-build -oyaml | yq eval '.spec.steps[0].image' -)
KANIKO_IMAGE=$(kubectl get task -n tap-tasks kaniko-build -oyaml | yq eval '.spec.steps[2].image' -)
CARVEL_IMAGE=$(kubectl get task -n tap-tasks carvel-package -oyaml | yq eval '.spec.steps[1].image' -)

# Create a temporary file to store replacement pairs
TEMP_FILE=$(mktemp)

# Populate the temporary file with old and new image references
# Format: OLD_IMAGE|NEW_IMAGE (one pair per line)

echo "image: supply-chain-docker-prod-local.usw1.packages.broadcom.com/packages/catalog-v1/ootb-templates/scripting-base@sha256:89c74ab6c164fb57b45dc53bd4d2cd43ea145754fb795f37d4679109707e41be|image: $SCRIPTING_BASE_IMAGE" >> "$TEMP_FILE"
echo "image: supply-chain-docker-prod-local.usw1.packages.broadcom.com/packages/catalog-v1/ootb-templates/kaniko@sha256:2c817acb57d6785a18b3e02bd2319b43990e040621c926fcc556219c99a5cdee|image: $KANIKO_IMAGE" >> "$TEMP_FILE"
echo "image: supply-chain-docker-prod-local.usw1.packages.broadcom.com/packages/catalog-v1/ootb-templates/carvel@sha256:40b6acd50cd1305a90e9a31feffb2ef30fd0141f8ac397c1a7acaad13533d5bd|image: $CARVEL_IMAGE" >> "$TEMP_FILE"

cat $TEMP_FILE

# Count the number of replacements to perform
NUM_REPLACEMENTS=$(wc -l < "$TEMP_FILE")
echo "Performing $NUM_REPLACEMENTS image replacements in YAML files..."

# Keep track of overall statistics
TOTAL_FILES=0
TOTAL_REPLACEMENTS=0

# Loop through all YAML files in the directory
for file in "$YAML_DIR"/*.yaml "$YAML_DIR"/*.yml; do
    if [ -f "$file" ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        echo "Processing file: $file"
        FILE_REPLACEMENTS=0
        
        # Process each replacement pair
        while IFS="|" read -r old_image new_image; do
            # Escape special characters for sed
            old_image_escaped=$(echo "$old_image" | sed 's/[\/&]/\\&/g')
            new_image_escaped=$(echo "$new_image" | sed 's/[\/&]/\\&/g')
            
            # Use sed to perform the replacement
            # The -i flag makes the changes in-place
            if [ "$(uname)" == "Darwin" ]; then
                # macOS requires an extension argument for -i
                sed -i '' "s/$old_image_escaped/$new_image_escaped/g" "$file"
            else
                # Linux version
                sed -i "s/$old_image_escaped/$new_image_escaped/g" "$file"
            fi
            
            # Check if replacement was made
            if grep -q "$new_image" "$file"; then
                echo "  - Replaced: $old_image"
                FILE_REPLACEMENTS=$((FILE_REPLACEMENTS + 1))
                TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + 1))
            fi
        done < "$TEMP_FILE"
        
        echo "  ✅ Made $FILE_REPLACEMENTS replacements in $file"
    fi
done

# Clean up temporary file
rm "$TEMP_FILE"

echo "--------------------------------"
echo "Summary:"
echo "Files processed: $TOTAL_FILES"
echo "Total replacements made: $TOTAL_REPLACEMENTS"
echo "Done!"