#!/usr/bin/bash
#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# Tool to convert a basic bash like .env configuration file to a json array for use in other tools in other
# programming languages.
#
# Version : v1.0.0
# Author  : André Hagoort
# Date    : 2026-05-22T15:44
#
# ----------------------------------------------------------------------------------------------------------------
# Changelog / History :
# 2026-05-20 | AH  | v1.0.0      | First edition of the scripot.
#


# Stop the script when:
# - a command fails
# - an undefined variable is used
# - a command in a pipe fails
set -euo pipefail

# Store the name of this script.
# This is used in the help text.
SCRIPT_NAME="$(basename "$0")"

# Create a timestamp for error and success messages.
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Default values.
# ENV_FILE is the input .env file.
# OUTPUT_FILE is empty by default, meaning output goes to the console.
ENV_FILE=".env"
OUTPUT_FILE=""
SILENT=0
UNKNOWN_OPTION=0
OUTPUT_PARM=0

# Show help information.
show_help() {
  echo "HOW-TO"
  echo "-------------------------------------------------------------------"
  cat <<EOF
Usage:
  $SCRIPT_NAME [OPTIONS] [ENV_FILE]

Convert a bash-style .env configuration file to JSON.

Arguments:
  ENV_FILE              Path to the .env file.
                        Default: .env

Options:
  -h, --help            Show this help message and exit.
  --file OUTPUT_FILE    Write JSON output to a file instead of the console.

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME .env
  $SCRIPT_NAME /path/to/config.env
  $SCRIPT_NAME .env --file config.json
  $SCRIPT_NAME --file config.json .env

Notes:
  - Empty lines are ignored.
  - Lines starting with # are ignored.
  - Optional "export" prefixes are supported.
  - Values are treated as text and are not executed.


EOF
}

# Read all command-line arguments one by one.
while [[ $# -gt 0 ]]; do
  case "$1" in

    # Show help and stop.
    -h|--help)
      show_help
      exit 0
      ;;

    # Use the next argument as the output file.
    --file)
      OUTPUT_PARM=1
      if [[ -n "${2:-}" && "${2:0:2}" != "--" ]]; then
         OUTPUT_FILE="$2"
         shift
      fi
      shift
      ;;

#    --file)
#      if [[ -z "${2:-}" ]]; then
#        echo "$TIMESTAMP [EROR] --file requires an output filename" >&2
#        exit 1
#      fi
#
#      OUTPUT_FILE="$2"
#      shift 2
#      ;;

    --silent)
      SILENT=1
      shift
      ;;

    # Unknown option.
    -*)
      UNKNOWN_OPTION="$1"
      shift
      ;;

    # Anything else is treated as the input .env file.
    *)
      ENV_FILE="$1"
      shift
      ;;
  esac
done

# 
if [[ -n "${UNKNOWN_OPTION}" ]]; then
   if (( ! SILENT )); then
      echo "$TIMESTAMP [EROR] unknown option: $1" >&2
      show_help
      exit 1
   fi
fi

if (( OUTPUT_PARM )); then
  if [[ ! -n "${OUTPUT_FILE}" ]]; then
    if (( ! SILENT )); then
       echo "$TIMESTAMP [EROR] --file requires an output filename, parameter ignored" >&2
    fi
  fi
fi

# Check if the input .env file exists.
if [[ ! -f "$ENV_FILE" ]]; then
  echo "$TIMESTAMP [EROR] file not found: $ENV_FILE" >&2
  exit 1
fi

# Convert the .env file to JSON and store the result in a variable.
JSON_OUTPUT="$(
awk '
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

function json_escape(s) {
  gsub(/\\/,"\\\\",s)
  gsub(/"/,"\\\"",s)
  gsub(/\t/,"\\t",s)
  gsub(/\r/,"\\r",s)
  return s
}

BEGIN {
  print "{"
  first = 1
}

/^[[:space:]]*$/ { next }
/^[[:space:]]*#/ { next }

{
  line = $0
  sub(/^[[:space:]]*export[[:space:]]+/, "", line)

  pos = index(line, "=")
  if (pos == 0) next

  key = trim(substr(line, 1, pos - 1))
  value = trim(substr(line, pos + 1))

  first_char = substr(value, 1, 1)
  last_char = substr(value, length(value), 1)

  if (first_char == "\"" && last_char == "\"") {
    value = substr(value, 2, length(value) - 2)
  }

  if (first_char == "\047" && last_char == "\047") {
    value = substr(value, 2, length(value) - 2)
  }

  if (!first) {
    print ","
  }

  printf "  \"%s\": \"%s\"", json_escape(key), json_escape(value)
  first = 0
}

END {
  print ""
  print "}"
}
' "$ENV_FILE"
)"

# If --file was used, write the JSON to that file.
# Otherwise, print the JSON to the console.
if [[ -n "$OUTPUT_FILE" ]]; then
  printf '%s\n' "$JSON_OUTPUT" > "$OUTPUT_FILE"

  if (( ! SILENT )); then
    echo "$TIMESTAMP [SUCS] written output to: $OUTPUT_FILE"
  fi

else
  if (( ! SILENT )); then
    printf '%s\n' "$JSON_OUTPUT"
  fi
fi
