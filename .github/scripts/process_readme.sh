#!/bin/bash

# Script to process README.md files and convert them to HTML
# This mimics the behavior of the MATLAB process_block_help.m function

set -e  # Exit on any error

# Get current year for copyright
CURRENT_YEAR=$(date +%Y)
COPYRIGHT_YEAR=${COPYRIGHT_YEAR:-$CURRENT_YEAR}

# Categories to process
CATEGORIES=("AIE" "HDL" "HLS" "UTIL" "GEN")

# Function to process a single README.md file
process_readme() {
    local readme_path="$1"
    local category="$2"
    local block_name="$3"
    
    if [[ ! -f "$readme_path" ]]; then
        echo "README.md not found in $category/$block_name, skipping..."
        return 0
    fi
    
    local dir=$(dirname "$readme_path")
    local html_file="${category}_${block_name}.html"
    local html_path="$dir/$html_file"
    
    # Check if we need to update (force update or file doesn't exist or README is newer)
    if [[ "$FORCE_UPDATE" == "true" ]] || [[ ! -f "$html_path" ]] || [[ "$readme_path" -nt "$html_path" ]]; then
        echo "Processing $category/$block_name..."
        
        # Read the README.md file
        local temp_md=$(mktemp)
        cp "$readme_path" "$temp_md"
        
        # Update copyright notice
        if grep -q "Copyright (C)" "$temp_md"; then
            # Update existing copyright year
            sed -i "s/Copyright (C) [0-9]\{4\}/Copyright (C) $COPYRIGHT_YEAR/g" "$temp_md"
        else
            # Add copyright notice
            echo "" >> "$temp_md"
            echo "--------------" >> "$temp_md"
            echo "Copyright (C) $COPYRIGHT_YEAR Advanced Micro Devices, Inc. All rights reserved." >> "$temp_md"
            echo "SPDX-License-Identifier: MIT" >> "$temp_md"
        fi
        
        # Replace internal README.md links with MATLAB help function calls
        # Pattern: (../[../]?(AIE|HDL|HLS|UTIL|GEN)?/blockname/README.md)
        sed -i -E "s|\(\.\./(\.\./)?((AIE\|HDL\|HLS\|UTIL\|GEN)/)?([^/)]+)/README\.md\)|(matlab:helpview(vmcHelp('name','\4','category','\3')))|g" "$temp_md"
        
        # Handle cases where category is not specified (use current category)
        sed -i -E "s|\(\.\./([^/)]+)/README\.md\)|(matlab:helpview(vmcHelp('name','\1','category','$category')))|g" "$temp_md"
        
        # Replace GitHub repository links with MATLAB function calls
        # Pattern: https://github.com/Xilinx/Vitis_Model_Composer/path/filename)
        sed -i -E "s|https://github\.com/Xilinx/Vitis_Model_Composer/[^)]+/([^)]+)\)|matlab:XmcExampleApi.getExample('\1'))|g" "$temp_md"
        
        # Handle Block_Help specific links differently
        sed -i -E "s|matlab:XmcExampleApi\.getExample\('([^']*Block_Help[^']*)'\)|matlab:openVMCExample('\1')|g" "$temp_md"
        
        # Get the title from the first line (# Title format)
        local title=$(head -n1 "$temp_md" | sed -E 's/^#\s*//')
        
        # Convert to HTML using pandoc
        local css_path="$(dirname "$0")/../xmc-matlab.css"
        if [[ ! -f "$css_path" ]]; then
            css_path="block_help/xmc-matlab.css"
        fi
        
        pandoc --from gfm --to html -s --embed-resources --no-highlight \
               -c "$css_path" --section-divs \
               --metadata title="$title" \
               "$temp_md" -o "$html_path"
        
        # Update the original README.md with copyright changes
        cp "$temp_md" "$readme_path"
        
        # Clean up
        rm "$temp_md"
        
        echo "Generated $html_file"
    else
        echo "Skipping $category/$block_name (up to date)"
    fi
}

# Function to process all README files in a category
process_category() {
    local category="$1"
    
    if [[ ! -d "$category" ]]; then
        echo "Category directory $category does not exist, skipping..."
        return 0
    fi
    
    echo "Processing category: $category"
    
    # Find all README.md files in subdirectories
    while IFS= read -r -d '' readme_file; do
        # Extract block name from path (e.g., AIE/block_name/README.md -> block_name)
        local block_name=$(dirname "$readme_file" | sed "s|^$category/||")
        
        # Skip if this is a nested directory structure
        if [[ "$block_name" == *"/"* ]]; then
            continue
        fi
        
        process_readme "$readme_file" "$category" "$block_name"
    done < <(find "$category" -maxdepth 2 -name "README.md" -print0)
}

# Main execution
echo "Starting README to HTML conversion..."
echo "Force update: $FORCE_UPDATE"
echo "Copyright year: $COPYRIGHT_YEAR"

# Check if we're in the right directory
if [[ ! -d "AIE" ]] || [[ ! -d "HDL" ]] || [[ ! -d "HLS" ]]; then
    echo "Error: This script should be run from the root directory containing AIE, HDL, HLS, UTIL, and GEN folders."
    exit 1
fi

# If specific files are provided (from changed files), process only those
if [[ -n "$CHANGED_FILES" ]] && [[ "$FORCE_UPDATE" != "true" ]]; then
    echo "Processing changed files: $CHANGED_FILES"
    
    for file in $CHANGED_FILES; do
        if [[ "$file" == */README.md ]]; then
            # Extract category and block name from path
            local category=$(echo "$file" | cut -d'/' -f1)
            local block_name=$(echo "$file" | sed -E "s|^[^/]+/([^/]+)/README\.md$|\1|")
            
            if [[ "$block_name" != *"/"* ]]; then
                process_readme "$file" "$category" "$block_name"
            fi
        fi
    done
else
    # Process all categories
    for category in "${CATEGORIES[@]}"; do
        process_category "$category"
    done
fi

echo "README to HTML conversion completed."