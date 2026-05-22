#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# Toolbox CORE bash library
# ---------------------------------------------------------------------------------------
#
# Version : v1.0.0-rc1
# Author  : André Hagoort
# Date    : 2026-05-20
#
# ---------------------------------------------------------------------------------------
# Description
#
# Set of general core functions for working with the bash library such as include libs,
# check dependencies and incluse a complete folder of libs.
#
# ---------------------------------------------------------------------------------------
# Function List
#
# core::is_library $filename()
# core::load_library $filename()
# core::load_libraries $directory()
#
# ---------------------------------------------------------------------------------------
# Changelog / History :
#
# 2026-05-19 | AH  | v1.0.0-rc01 | First Release Candate
#
#
# ---------------------------------------------------------------------------------------

# append file to LIB_REGISTER
if ! declare -p LIB_REGISTER >/dev/null 2>&1; then declare -gA LIB_REGISTER; fi
LIB_REGISTER["bashlib-lib.sh:version"]="v1.0.0-rc1";

# register dependencies of libraries in the toolbox.
LIB_REGISTER["bashlib-lib.sh:dependencies"]="bashlib-log.sh bashlib-ftp.sh"

# add global default color schemes if they don't exist.
if [[ ! -v env_LOG_TYPE_CRIT_COLOR ]]; then declare -g env_LOG_TYPE_CRIT_COLOR='\033[1;37;41m'; fi
if [[ ! -v env_LOG_TYPE_EROR_COLOR ]]; then declare -g env_LOG_TYPE_EROR_COLOR='\033[0;31m'; fi
if [[ ! -v env_LOG_TYPE_WARN_COLOR ]]; then declare -g env_LOG_TYPE_WARN_COLOR='\033[1;33m'; fi
if [[ ! -v env_LOG_TYPE_INFO_COLOR ]]; then declare -g env_LOG_TYPE_INFO_COLOR='\033[0;90m'; fi
if [[ ! -v env_LOG_TYPE_NOTC_COLOR ]]; then declare -g env_LOG_TYPE_NOTC_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_DEBG_COLOR ]]; then declare -g env_LOG_TYPE_DEBG_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_UNKN_COLOR ]]; then declare -g env_LOG_TYPE_UNKN_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_SUCS_COLOR ]]; then declare -g env_LOG_TYPE_SUCS_COLOR='\033[1;37m'; fi
if [[ ! -v env_COLOR_RESET ]]; then declare -g env_COLOR_RESET='\033[1;37m'; fi

# get the filename from the full path.
#
core::get_filename(){
	FULL_PATH="$1"
	echo "${FULL_PATH##*/}"
}

##
# Check if a Bash function exists.
#
# This function validates whether the specified function
# name is currently loaded and available in the shell.
#
# @param $1 Function name
#
# @return
#   0 Function exists
#   1 Function does not exist
#
# @example
#   if core::function_exists "log::log"; then
#       echo "Logger loaded"
#   fi
#
# @example
#   core::function_exists "core::load_library"
#
core::function_exists() {

    local FUNCTION_NAME="$1"

    if declare -F "$FUNCTION_NAME" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

##
# Validate whether a file is a Bash library file.
#
# A valid library file:
#   - Must exist
#   - Must be a regular file
#   - Must NOT be executable
#   - Must NOT contain a shebang line
#
# @param $1 Full path and filename
#
# @return
#   0 File is a valid library
#   1 File does not exist or is not a regular file
#   2 File is executable
#   3 File contains a shebang line
#
# @example
#   if core::is_library "./lib/test.lib.sh"; then
#       echo "Valid library"
#   fi
#
# @example
#   core::is_library "/opt/bashlib/bashlib-log.lib.sh"
#
core::is_library() {

    local FILE="$1"

    # must exist and be a regular file
    [[ ! -f "$FILE" ]] && return 1

    # executable files are not libraries
    [[ -x "$FILE" ]] && return 2

    # read first line to validate if file has a shebang line.
    local FIRST_LINE
    FIRST_LINE="$(head -n 1 "$FILE" 2>/dev/null)"

    # files with shebang are not libraries
    [[ "$FIRST_LINE" == '#!'* ]] && return 3 

    return 0

}

##
# Include (load) a single Bash library file.
#
# The specified library file is validated using
# core::is_library() before inclusion.
#
# A library is considered successfully loaded when it
# registers itself in the LIB_REGISTER array using:
#
#   LIB_REGISTER["<filename>:version"]
#
# Already loaded libraries are skipped automatically.
#
# @param $1 Full path and filename of the library
#
# @return
#   0 Library successfully loaded or already loaded
#   1 File is not a valid library
#   2 Library inclusion failed
#
# @example
#   core::load_library "./lib/bashlib-log.lib.sh"
#
# @example
#   core::load_library "${BASHLIB_DIR}/bashlib-core.lib.sh"
#
core::load_library() {

    local FILE=$1

    if core::is_library "$FILE"; then

	FILENAME="$(core::get_filename "$FILE")"

        if [[ "${LIB_REGISTER[${FILENAME}:version]}" == "" ]]; then

            source "$FILE"

            if [[ "${LIB_REGISTER[${FILENAME}:version]}" == "" ]]; then
               log::log_error "Including $FILE failed"
	       return 2
            else
               log::log_debug "Including $FILE succes"
	       return 0
            fi

        else
            log::log_debug "$FILE skipped because it's already included"
	    return 0
        fi
    else
       log::log_debug "$FILE is not a library" 
    fi

    return 1
}

##
# Include (load) all Bash library files from a directory.
#
# The function loads all valid library files from the given directory.
# A file is considered a valid library when core::is_library() returns
# success.
#
# The input path may include a filename filter such as:
#
#   /opt/bashlib/*.lib.sh
#
# If no filter is provided, "*.sh" is used as default.
#
# Subdirectories can optionally be scanned by setting the depth argument.
#
# @param $1 Directory path, optionally including a file filter
# @param $2 Optional recursion depth for subdirectories, default is 0
#
# @return
#   0 Libraries loaded successfully
#   1 Missing argument or library directory not found
#
# @example
#   core::load_libraries "/opt/bashlib"
#
# @example
#   core::load_libraries "/opt/bashlib/*.lib.sh"
#
# @example
#   core::load_libraries "/opt/bashlib/*.lib.sh" 2
#
core::load_libraries() {

    # if $1 does not exist, exit with error
    if (( $# < 1 )); then
         log::log_error "Library directory not found: $LIB_DIR" >&2
	return 1;
    fi

    local FULL_PATH="$1"
    local LAST_PART
    local -i LIB_DIG=0
    local LIB_DIR
    local LIB_FILTER
    local FILE
    local NEW_DIG

    # if $2 exists, use it as dig depth
    if (( $# >= 2 )); then
        LIB_DIG="$2"
    fi

    # read the directory and filter part of the path
    LAST_PART="${FULL_PATH##*/}"

    # split the FULL_PATH as received as argument 1.
    if [[ "$LAST_PART" == *[\*\?\[]* ]]; then
        LIB_DIR="${FULL_PATH%/*}"
        LIB_FILTER="$LAST_PART"
    else
        LIB_DIR="$FULL_PATH"
        LIB_FILTER="*.sh"
    fi

    # check if the library directory exists
    [[ -d "$LIB_DIR" ]] || {
        log:log_error "Library directory not found: $LIB_DIR" >&2
        return 1
    }

    while IFS= read -r FILE; do

        if [[ -d "$FILE" ]]; then

            if (( LIB_DIG > 0 )); then
                NEW_DIG=$(( LIB_DIG - 1 ))
                core::load_libraries "$FILE/$LIB_FILTER" "$NEW_DIG"
            fi

        elif [[ -f "$FILE" ]]; then

            if core::is_library "$FILE"; then
                core::load_library "$FILE"
            fi

        fi

    done < <(
        find "$LIB_DIR" -maxdepth 1 \( -type d -o \( -type f -name "$LIB_FILTER" \) \) | sort
    )

    return 0
}

##
# Return the configured ANSI color code for a log type.
#
# @param $1 Log type
#
# Supported log types:
#   EROR = Error messages
#   WARN = Warning messages
#   INFO = Informational messages
#   DBUG = Debug messages
#
# @return Echoes the ANSI color code to stdout.
#
# @example
#   COLOR="$(core::log_color "INFO")"
#   echo -e "${COLOR}Information${env_COLOR_RESET}"
#
core::log_color(){
  case "$1" in 
    EROR)
	echo "${env_LOG_TYPE_EROR_COLOR}"
	;;
    WARN)
	echo "${env_LOG_TYPE_WARN_COLOR}"
    	;;
    INFO)
	echo "${env_LOG_TYPE_INFO_COLOR}"
    	;;
    DBUG)
	echo "${env_LOG_TYPE_DEBG_COLOR}"
    	;;
    *)
    	echo "${env_COLOR_RESET}"
        ;;
    esac
}

##
# Write a formatted log message to the console.
#
# If the external function log::log exists, the function call
# is forwarded to that implementation.
#
# @param $1 Log type
# @param $2...$n Log message
#
# @return
#   0 Success
#   1 Invalid argument count
#
# @example
#   core::log "INFO" "Application started"
#
# @example
#   core::log "EROR" "Database connection failed"
#
core::log(){
    # use log::log if available.
    if declare -F log::log >/dev/null 2>&1; then
	log::log "$@" 
	return $?
    fi

    # validate if the function call has a minimum of 2 arguments.
    if (( $# < 2 )); then return 1; fi

    # set variables.
    local TYPE="$1"
    shift
    local MESSAGE="$*" #include all arguments in single message.
    local TIMESTAMP
    local COLOR="$(core::log_color "$TYPE")"

    # create timestamp
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

    # write logfile to console.
    echo -e "$TIMESTAMP [${COLOR}${TYPE}${env_COLOR_RESET}] $MESSAGE"

    return 0
}


##
# Write a debug log message.
#
# This is a wrapper around core::log() using the
# predefined log type DBUG.
#
# @param $1...$n Debug message
#
# @return
#   0 Success
#   1 Invalid argument count
#
# @example
#   core::log_debug "Loading configuration"
#
# @example
#   core::log_debug "Variable value:" "$TEST"
#
core::log_debug() {
    core::log "DBUG" "$@"
}

##
# Write an error log message.
#
# This is a wrapper around core::log() using the
# predefined log type EROR.
#
# @param $1...$n Error message
#
# @return
#   0 Success
#   1 Invalid argument count
#
# @example
#   core::log_error "Unable to connect to database"
#
# @example
#   core::log_error "Configuration file missing:" "$FILE"
#
core::log_error(){
    core::log "EROR" "$@"
}

##
# Write a warning log message.
#
# This is a wrapper around core::log() using the
# predefined log type WARN.
#
# @param $1...$n Warning message
#
# @return
#   0 Success
#   1 Invalid argument count
#
# @example
#   core::log_warning "Configuration file not found"
#
# @example
#   core::log_warning "Retrying connection to server"
#
core::log_warning(){
    core::log "WARN" "$@"
}

##
# Write an informational log message.
#
# This is a wrapper around core::log() using the
# predefined log type INFO.
#
# @param $1...$n Information message
#
# @return
#   0 Success
#   1 Invalid argument count
#
# @example
#   core::log_info "Application started"
#
# @example
#   core::log_info "Loaded library:" "$FILE"
#
core::log_info(){
    core::log "INFO" "$@"
}
