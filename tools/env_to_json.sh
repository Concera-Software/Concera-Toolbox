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
#
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

AUTO_INSTALL=0
OUTPUT_FILE=""
ENV_FILE=""

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

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME .env
  $SCRIPT_NAME /path/to/config.env
  $SCRIPT_NAME .env > config.json

Notes:
  - Empty lines are ignored.
  - Lines starting with # are ignored.
  - Optional "export" prefixes are supported.
  - Values are treated as text and are not executed.
EOF

echo
echo
}

# set log line timestamp
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Use the first argument as the .env file.
# If no argument is given, use ".env".
ENV_FILE="${1:-.env}"

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
      # The next argument must be the output filename.
      if [[ -z "${2:-}" ]]; then
        echo "$TIMESTAMP [EROR] --file requires an output filename" >&2
        exit 1
      fi

      OUTPUT_FILE="$2"
      shift 2
      ;;

    -*)
      echo "$TIMESTAMP [EROR] unknown option: $1" >&2
      show_help
      exit 1
      ;;

    *)
      # Anything that is not an option is treated as the JSON file.
      ENV_FILE="$1"
      shift
      ;;
  esac
done

# Check if the file exists.
if [[ ! -f "$ENV_FILE" ]]; then

  echo "$TIMESTAMP [EROR] file not found: $ENV_FILE" >&2
  exit 1
fi

awk '
# Remove spaces/tabs from the beginning and end of a string.
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

# Escape characters that would break JSON.
function json_escape(s) {
  gsub(/\\/,"\\\\",s)    # Escape backslashes
  gsub(/"/,"\\\"",s)     # Escape double quotes
  gsub(/\t/,"\\t",s)     # Escape tabs
  gsub(/\r/,"\\r",s)     # Escape carriage returns
  return s
}

# Print the opening JSON bracket.
BEGIN {
  print "{"
  first = 1
}

# Skip empty lines.
/^[[:space:]]*$/ { next }

# Skip comment lines starting with #.
/^[[:space:]]*#/ { next }

# Process all other lines.
{
  line = $0

  # Support lines like:
  # export NAME=value
  sub(/^[[:space:]]*export[[:space:]]+/, "", line)

  # Find the first = character.
  pos = index(line, "=")

  # If there is no =, ignore the line.
  if (pos == 0) next

  # Everything before = is the key.
  key = trim(substr(line, 1, pos - 1))

  # Everything after = is the value.
  value = trim(substr(line, pos + 1))

  # Get the first and last character of the value.
  first_char = substr(value, 1, 1)
  last_char = substr(value, length(value), 1)

  # Remove surrounding double quotes:
  # NAME="value" becomes NAME=value
  if (first_char == "\"" && last_char == "\"") {
    value = substr(value, 2, length(value) - 2)
  }

  # Remove surrounding single quotes:
  # NAME='\''value'\'' becomes NAME=value
  #
  # \047 is the ASCII code for a single quote.
  # This avoids confusing Bash and awk quoting.
  if (first_char == "\047" && last_char == "\047") {
    value = substr(value, 2, length(value) - 2)
  }

  # Add a comma before every JSON item except the first one.
  if (!first) {
    print ","
  }

  # Print the JSON key/value pair.
  printf "  \"%s\": \"%s\"", json_escape(key), json_escape(value)

  # Mark that the first item has now been printed.
  first = 0
}

# Print the closing JSON bracket.
END {
  print ""
  print "}"
}
' "$ENV_FILE"
