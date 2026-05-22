#!/usr/bin/env bash
set -euo pipefail

#
# Bash Documentation Generator Wrapper
#
# This script executes either the HTML or Markdown
# documentation generator based on the requested format.
#
# Arguments:
#   $1 = Output format (HTML or MD)
#   $2 = Source directory
#   $3 = Output filename
#
# Examples:
#
#   ./bashdoc.sh HTML ./libs ./docs/bashdoc.html
#
#   ./bashdoc.sh MD ./libs ./docs/bashdoc.md
#

FORMAT="${1:-}"
SOURCE_DIR="${2:-.}"
OUTPUT_FILE="${3:-}"

#
# resolve directory where this script itself is located
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# generators located in same directory as this script
#
HTML_GENERATOR="${SCRIPT_DIR}/toolbox-create-doc-html.sh"
MD_GENERATOR="${SCRIPT_DIR}/toolbox-create-doc-md.sh"

#
# validate arguments
#
if [[ -z "$FORMAT" ]]; then
    echo "ERROR: Missing output format (HTML or MD)"
    exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "ERROR: Missing output filename"
    exit 1
fi

#
# normalize format
#
FORMAT="${FORMAT^^}"

#
# run requested generator
#
case "$FORMAT" in

    HTML)

        if [[ ! -x "$HTML_GENERATOR" ]]; then
            echo "ERROR: HTML generator not found or not executable:"
            echo "  $HTML_GENERATOR"
            exit 1
        fi

        "$HTML_GENERATOR" "$SOURCE_DIR" "$OUTPUT_FILE"
        ;;

    MD)

        if [[ ! -x "$MD_GENERATOR" ]]; then
            echo "ERROR: Markdown generator not found or not executable:"
            echo "  $MD_GENERATOR"
            exit 1
        fi

        "$MD_GENERATOR" "$SOURCE_DIR" "$OUTPUT_FILE"
        ;;

    *)

        echo "ERROR: Invalid format: $FORMAT"
        echo "Supported formats:"
        echo "  HTML"
        echo "  MD"

        exit 1
        ;;

esac

echo "Documentation successfully generated:"
echo "  $OUTPUT_FILE"
