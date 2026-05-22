#!/usr/bin/bash
#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# Tool to converting a json configuration file to a basic bash .env configuration file.
#
# Version : v1.0.0
# Author  : André Hagoort
# Date    : 2026-05-22T15:44
#
# ----------------------------------------------------------------------------------------------------------------
# Changelog / History :
# 2026-05-20 | AH  | v1.0.0      | First edition of the scripot.
#

# Stop the script if:
# - a command fails
# - an undefined variable is used
# - a command in a pipe fails
#
#

# Stop the script if something goes wrong.
#
# -e  = stop if a command fails
# -u  = stop if an undefined variable is used
# -o pipefail = stop if a command inside a pipe fails

# Stop the script if something goes wrong.
#
# -e  = stop if a command fails
# -u  = stop if an undefined variable is used
# -o pipefail = stop if a command inside a pipe fails
set -euo pipefail

# Store the name of this script.
# This is used in the help text.
SCRIPT_NAME="$(basename "$0")"

# Create a timestamp for error messages.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# By default, do not automatically install jq.
# 0 = false
# 1 = true
AUTO_INSTALL=0

# This variable will later contain the JSON filename.
JSON_FILE=""

# create default output file.
OUTPUT_FILE=""
OUTPUT_PARM=0
UNKNOWN_OPTION=0
SILENT=0

# Function that prints help information.
show_help() {
  if (( SILENT )); then return 0; fi

  cat <<EOF
Usage:
  $SCRIPT_NAME [OPTIONS] JSON_FILE

Convert a simple JSON object to a bash-style .env file.

Options:
  -h, --help            Show this help message and exit.
  --autoinstall         Automatically install required tools.
  --silent		Suppress all output, also output of the configfile. If the --file option
			is not used, default file .env will be used to output the data.
  --file OUTPUT_FILE    Write output to a file instead of the console.

Examples:
  $SCRIPT_NAME config.json
  $SCRIPT_NAME config.json --file .env
  $SCRIPT_NAME --autoinstall config.json --file .env
  $SCRIPT_NAME --autoinstall config.json --file .env --silent

EOF
}

# Read all command-line arguments.
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;

    --autoinstall)
      AUTO_INSTALL=1
      shift
      ;;

    --file)
      OUTPUT_PARM=1
      if [[ -n "${2:-}" && "${2:0:2}" != "--" ]]; then
         OUTPUT_FILE="$2"
         shift
      fi
      shift
      ;;

    --silent)
      SILENT=1
      AUTO_INSTALL=1
      shift
      ;;

    -*)
      UNKNOWN_OPTION="$1"
      shift
      ;;

    *)
      # Anything that is not an option is treated as the JSON file.
      JSON_FILE="$1"
      shift
      ;;
  esac
done

if [[ ! -n "${UNKNOWN_OPTION}" ]]; then
   if (( ! SILENT )); then
      echo "$TIMESTAMP [EROR] unknown option ${UNKNOWN_OPTION}" >&2
      show_help
      exit 0
   fi
fi

if (( SILENT )); then
   if [[ ! -n "${OUTPUT_FILE}" ]]; then
      OUTPUT_FILE=".env"
   fi
fi

if (( OUTPUT_PARM )); then
  if [[ ! -n "${OUTPUT_FILE}" ]]; then
    if (( ! SILENT )); then
       echo "$TIMESTAMP [EROR] --file requires an output filename, parameter ignored" >&2
    fi
  fi
fi

# A JSON file is required.
if [[ -z "$JSON_FILE" ]]; then
  if (( ! SILENT )); then
     show_help
  fi
  exit 1
fi

# Check if the JSON file exists.
if [[ ! -f "$JSON_FILE" ]]; then
  if (( ! SILENT )); then
     echo "$TIMESTAMP [EROR] file not found: $JSON_FILE" >&2
  fi
  exit 1
fi

# Check if jq is installed.
if ! command -v jq >/dev/null 2>&1; then
  if (( AUTO_INSTALL )); then
    sudo apt update
    sudo apt install -y jq
  else
    echo "jq is required but not installed."
    read -r -p "Do you want to install jq now? [y/N] " INSTALL_JQ

    case "$INSTALL_JQ" in
      y|Y|yes|YES)
        sudo apt update
        sudo apt install -y jq
        ;;
      *)
        if (( ! SILENT )); then
	        echo "$TIMESTAMP [EROR] jq is required. Please install it and try again." >&2
        fi
        exit 1
        ;;
    esac
  fi
fi

# Convert JSON to .env format and store it in a variable.
#
# jq:
# - reads the JSON file
# - loops through every key/value pair
# - writes lines like NAME='value'
ENV_OUTPUT="$(
  jq -r '
    to_entries[]
    | "\(.key)=\(.value | tostring | @sh)"
  ' "$JSON_FILE"
)"

# If --file was used, write to that file.
# Otherwise, print to the console.
if [[ -n "$OUTPUT_FILE" ]]; then
  printf '%s\n' "$ENV_OUTPUT" > "$OUTPUT_FILE"

  if (( ! SILENT )); then
     echo "$TIMESTAMP [SUCS] written output to: $OUTPUT_FILE"
  fi

else

  if (( ! SILENT )); then
    printf '%s\n' "$ENV_OUTPUT"
  fi

fi
