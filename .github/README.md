# GitHub Actions for VMC Help

This directory contains GitHub Actions workflows and scripts for automatically processing README.md files in the VMC_Help repository.

## Files

- `workflows/update-block-help.yml`: GitHub Action workflow that triggers on README.md changes
- `scripts/process_readme.sh`: Shell script that processes README.md files and converts them to HTML

## How it works

The workflow automatically:

1. **Triggers** when README.md files are modified in any of the following directories:
   - `AIE/*/README.md`
   - `HDL/*/README.md`
   - `HLS/*/README.md`
   - `UTIL/*/README.md`
   - `GEN/*/README.md`

2. **Processes** the changed files by:
   - Updating copyright notices to the current year
   - Converting internal links to MATLAB help function calls
   - Converting GitHub repository links to MATLAB example calls
   - Converting Markdown to HTML using Pandoc

3. **Commits** the generated HTML files back to the repository

## Manual Trigger

You can also manually trigger the workflow to force update all HTML files:

1. Go to the Actions tab in the GitHub repository
2. Select "Update Block Help HTML" workflow
3. Click "Run workflow"
4. Check "Force update all HTML files" if needed
5. Click "Run workflow"

## Requirements

The workflow requires:
- Pandoc (automatically installed by the workflow)
- The CSS file `block_help/xmc-matlab.css` for styling
- Write permissions to the repository (uses GITHUB_TOKEN)

## Equivalent MATLAB Function

This GitHub Action replicates the behavior of the `process_block_help.m` MATLAB function, but runs automatically on every README.md change instead of requiring manual execution.