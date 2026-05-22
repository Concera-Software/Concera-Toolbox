#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# Library for Logging functions
#
# ----------------------------------------------------------------------------------------------------------------
#
# Version : v1.0.2
# Author  : André Hagoort
# Date    : 2026-05-22
#
# ----------------------------------------------------------------------------------------------------------------
# Description
#
# Set of functions to facillitate stadardized logging to console, file and syslog for use withing bash scripts
# Library is compatible with the load_libraries and load_library function in the toolbox-core.sh library.
#
# ----------------------------------------------------------------------------------------------------------------
# Function List
#
# string::tolower()
# string::toupper()
#
# logger::parse_function_args()
# logger::get_message_type()
# logger::log_to_console()
# logger::log_to_file()
# logger::log_to_syslog()
# logger::log(){
# logger::log_critical(){
# logger::log_error(){
# logger::log_warning(){
# logger::log_info(){
# logger::log_notice(){
# logger::log_debug(){
#
# ----------------------------------------------------------------------------------------------------------------
# Globel (.env) variables used / created
#
# env_LOG_LEVEL_DEBUG
# env_LOG_LEVEL_DEBUG
# env_LOG_LEVEL_SYSLOG
# env_LOG_LEVEL_FILE
# env_LOG_FILE
#
# env_LOG_TYPE_CRIT
# env_LOG_TYPE_EROR
# env_LOG_TYPE_WARN
# env_LOG_TYPE_INFO
# env_LOG_TYPE_NOTC
# env_LOG_TYPE_DEBG
# env_LOG_TYPE_UNKN
#
# env_PROCESS_NAME
#
# ----------------------------------------------------------------------------------------------------------------
# Changelog / History
#
# 2026-05-22 | AH  | v1.0.3      | Fixed minor documenting errors
# 2026-05-20 | AH  | v1.0.2      | Added colors to console messages.
# 2026-05-20 | AH  | v1.0.1      | Fixed an issue with message levels preventing messages to be handled correctly.
# 2026-05-20 | AH | v1.0.0      | Finalized and documented first version
# 2026-05-19 | AH | v1.0.0-rc01 | First Release Candate
#

# append file to LIB_REGISTER
if ! declare -p LIB_REGISTER >/dev/null 2>&1; then declare -gA LIB_REGISTER; fi
LIB_REGISTER["bashlib-logging.sh::include"]="ok"

# register dependencies of libraries in the toolbox.
LIB_REGISTER["bashlib-logging.sh::dependencies"]=(
	"bashlib-core.sh"
)


# ---------------------------------------------------------------------------------------
# LOG FUNCTION to SCREEN/FILE/SYSLOG
# ---------------------------------------------------------------------------------------
#

# Initiate maximul level of debug message. Add this ENV variable
# to the global .env file to use it as a globel setting. The debug level is 
# applicable for all logging, console, file and console. To limit the 
# use the levels wisely to craete the optimal loglevel for each option.
#
if [[ ! -v env_LOG_LEVEL_DEBUG ]]; then declare -g env_LOG_LEVEL_DEBUG=0; fi

# Initiate maximul level of message written to console. Add this ENV variable
# to the global .env file to use it as a globel setting.
#
if [[ ! -v env_LOG_LEVEL_CONSOLE ]]; then declare -g env_LOG_LEVEL_CONSOLE=999; fi

# Initiate maximul level of message written to syslog. Add this ENV variable
# to the global .env file to use it as a globel setting.
#
if [[ ! -v env_LOG_LEVEL_SYSLOG ]]; then declare -g env_LOG_LEVEL_SYSLOG=999; fi

# Initiate maximul level of message written to a logfile. Add this ENV variable
# to the global .env file to use it as a globel setting.
#
if [[ ! -v env_LOG_LEVEL_FILE ]]; then declare -g env_LOG_LEVEL_FILE=999; fi

# Initiate the logfile used to log to. Add this ENV variable
# to the global .env file to use it as a globel setting.
#
if [[ ! -v env_LOG_FILE ]]; then declare -g env_LOG_FILE="/var/log/bashlib.log"; fi

# Set default Message TYPES and TYPE colors. Add this ENV variable to the global .env file
# to use it as a globel setting.
#
if [[ ! -v env_LOG_TYPE_CRIT ]]; then declare -g env_LOG_TYPE_CRIT="CRIT"; fi
if [[ ! -v env_LOG_TYPE_EROR ]]; then declare -g env_LOG_TYPE_EROR="EROR"; fi
if [[ ! -v env_LOG_TYPE_WARN ]]; then declare -g env_LOG_TYPE_WARN="WARN"; fi
if [[ ! -v env_LOG_TYPE_INFO ]]; then declare -g env_LOG_TYPE_INFO="INFO"; fi
if [[ ! -v env_LOG_TYPE_NOTC ]]; then declare -g env_LOG_TYPE_NOTC="NOTC"; fi
if [[ ! -v env_LOG_TYPE_DEBG ]]; then declare -g env_LOG_TYPE_DEBG="DEBG"; fi
if [[ ! -v env_LOG_TYPE_UNKN ]]; then declare -g env_LOG_TYPE_UNKN="UNKN"; fi
if [[ ! -v env_LOG_TYPE_SUCS ]]; then declare -g env_LOG_TYPE_SUCS="SUCS"; fi

# Add global default color scheme if it does not exist
#
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

# Set default processName to pass to the syslog. Add this ENV variable to the\
# global .env file to use it as a globel setting.
if [[ ! -v env_PROCESS_NAME ]]; then declare -g env_PROCESS_NAME=$0; fi

#
# convert string to lower case.
#
# $1 TEXT (string) : text to convert to lower case
# return (string) lower case text
#
# example
#
# 	RESULT="$(string::tolower "$TEXT")"
#
string::tolower(){
   echo "{$1,,}"
}

#
# convert string to lower case.
#
# $1 TEXT (string) : text to convert to upper case
# return (string) upper case text
#
# example
#
# 	RESULT="$(string::toupper "$TEXT")"
#
string::toupper(){
   echo "{$1^^}"
}

#
# parse arguments from the parameter $1 (array) into the array with name $2
#
# example:
#
#	local -A ARGUMENTS
# 	logger::parse_function_args ARGUMENTS "$@"
# 	for INDEX in "${!ARGUMENTS[@]}"; do echo "$INDEX = ${ARGUMENTS[$INDEX]}"; done
#
logger::parse_function_args(){

    local ARRAY_NAME="${1}"
    shift

    declare -gA "$ARRAY_NAME"

    INDEX=1
    for ARG in "$@"; do

        case "$ARG" in
            --*=*)
                local KEY="${ARG%%=*}"
                local VALUE="${ARG#*=}"
                KEY="${KEY#--}"
                eval "${ARRAY_NAME}[\"$KEY\"]=\"\$VALUE\""
                ;;
            --*)
                local KEY="${ARG#--}"
                eval "${ARRAY_NAME}[\"$KEY\"]=1"
                ;;
            *)
                local VALUE="${ARG}"
                eval "${ARRAY_NAME}[\"$INDEX\"]=\"\$VALUE\""
                ;;
        esac

        ((INDEX++))

    done
}

# fetch message color matching a specific type of message
#
logger::get_message_type_color(){

    local TYPE="${1,,}" #store argument 1 in lower case in variable.
    local COLOR=""      #new type based on switch

    # standarize message types.
    #
    case "$TYPE" in
        critical|critical|crit|crt)
            COLOR=$env_LOG_TYPE_CRIT_COLOR
            ;;
        error|eror|err)
	    COLOR=$env_LOG_TYPE_EROR_COLOR
            ;;
        warning|warn|wrn)
            COLOR=$env_LOG_TYPE_WARN_COLOR
            ;;
        debug|debg|dbg)
            COLOR=$env_LOG_TYPE_DEBG_COLOR
            ;;
        notice|not)
            COLOR=$env_LOG_TYPE_NOTC_COLOR
             ;;
        info|inf|nfo)
            COLOR=$env_LOG_TYPE_INFO_COLOR
            ;;
        succes|sucs)
            COLOR=$env_LOG_TYPE_SUCS_COLOR
            ;;
        *)
            COLOR=$env_LOG_TYPE_UNKN_COLOR
            ;;
    esac

    # return stadardized log-type.
    echo $COLOR
}


# get stadard message type bases on several types of spelling of the
# message types.
#
# example:
#
#       MSGTYPE="WARNING"
# 	TYPE="$(logger::get_message_type "$MSGTYPE")"
#	echo "$TYPE" #output should stadarized data as configured in $env_LOG_TYPE_*
#
logger::get_message_type(){

    local TYPE="${1,,}" #store argument 1 in lower case in variable.
    local NTYPE=""      #new type based on switch

    # standarize message types.
    #
    case "$TYPE" in
        critical|crit|crt)
            NTYPE=$env_LOG_TYPE_CRIT
            ;;
        error|eror|err)
            NTYPE=$env_LOG_TYPE_EROR
            ;;
        warning|warn|wrn)
            NTYPE=$env_LOG_TYPE_WARN
            ;;
        debug|debg|dbg)
            NTYPE=$env_LOG_TYPE_DEBG
            ;;
        notice|notc|not)
            NTYPE=$env_LOG_TYPE_NOTC
            ;;
        info|inf|nfo)
            NTYPE=$env_LOG_TYPE_INFO
            ;;
	succes|sucs)
	    NTYPE=$env_LOG_TYPE_SUCS
            ;;
	*)
	    NTYPE=$env_LOG_TYPE_UNKN
	    ;;
    esac

    # return stadardized log-type.
    echo $NTYPE
}

#
# function to write log to console
#
# $1 TYPE             : type of message
# $2 MESSAGE          : the message to log
# $3 TIMESTAMP        : the timestamp of the message
# $4 LOG_LEVEL_FILE   : loglevel up to which the message is written to console
# $5 MSG_LEVEL        : log level of the message
# $6 LOG_LEVEL_DEBUG  : active debug level, only applicable to debug messages.
#
logger::log_to_console(){

    local TYPE="$1"
    local MESSAGE="$2"
    local TIMESTAMP="$3"
    local LOG_LEVEL_CONSOLE=$4
    local MSG_LEVEL=$5
    local LOG_LEVEL_DEBUG=$6

    # Write to console

    if [[ $LOG_LEVEL_CONSOLE -ge $MSG_LEVEL && $LOG_LEVEL_CONSOLE -gt 0 ]]; then

        local COLOR="$(logger::get_message_type_color "$TYPE")"

        case "$TYPE" in
           $env_LOG_TYPE_DEBG)
                if [[ $LOG_LEVEL_DEBUG -ge $MSG_LEVEL && $LOG_LEVEL_DEBUG -gt 0 ]]; then
                        echo -e "$TIMESTAMP ${COLOR}[${TYPE}]${env_COLOR_RESET} $MESSAGE";
                fi
                ;;
           *)
                echo -e "$TIMESTAMP ${COLOR}[${TYPE}]${env_COLOR_RESET} $MESSAGE";
                ;;
        esac

    fi

}

#
# function to write to log file based on the arguments:
#
# $1 TYPE	      : type of message
# $2 MESSAGE          : the message to log
# $3 TIMESTAMP        : the timestamp of the message
# $4 LOG_LEVEL_FILE   : loglevel up to which the message is written to log file
# $5 MSG_LEVEL        : log level of the message
# $6 LOG_LEVEL_DEBUG  : active debug level, only applicable to debug messages.
# $7 LOG_FILE         : file to log to.
#
logger::log_to_file(){

    local TYPE="$1"
    local MESSAGE="$2"
    local TIMESTAMP="$3"
    local LOG_LEVEL_FILE=$4
    local MSG_LEVEL=$5
    local LOG_LEVEL_DEBUG=$6
    local LOG_FILE="$7"

    # alert if logfile is empty
    if [[ "$LOG_FILE" == "" && $env_LOG_LEVEL_SYSLOG -gt 0 ]]; then
	logger -p $env_LOG_TYPE_EROR "Filename to log to is not supplied in forlogline '$MESSAGE'"
    fi

    # Write to file
    if [[ $LOG_LEVEL_FILE -ge $MSG_LEVEL && $LOG_LEVEL_FILE -gt 0 ]]; then
        case "$TYPE" in
           $env_LOG_TYPE_DEBG)
                if [[ $LOG_LEVEL_DEBUG -ge $MSG_LEVEL && $LOG_LEVEL_DEBUG -gt 0 ]]; then
                        echo "$TIMESTAMP [$TYPE] $MESSAGE" >> "$LOG_FILE";
                fi
                ;;
           *)
                echo "$TIMESTAMP [$TYPE] $MESSAGE" >> "$LOG_FILE";
                ;;
        esac
    fi

}

#
# function to write to syslog based on the arguments:
#
# $1 TYPE             : type of message
# $2 MESSAGE          : the message to log
# $3 TIMESTAMP        : the timestamp of the message
# $4 LOG_LEVEL_SYSLOG : loglevel up to which the message is written to syslog
# $5 MSG_LEVEL        : log level of the message
# $6 LOG_LEVEL_DEBUG  : active debug level, only applicable to debug messages.
# $7 ORIGIN           : Process name, what script/process is logging
#
logger::log_to_syslog(){

    local TYPE="$1"
    local MESSAGE="$2"
    local TIMESTAMP="$3"
    local LOG_LEVEL_SYSLOG=$4
    local MSG_LEVEL=$5
    local LOG_LEVEL_DEBUG=$6
    local ORIGIN="$7"

    if [[ $LOG_LEVEL_SYSLOG -ge $MSG_LEVEL && $LOG_LEVEL_SYSLOG -gt 0 ]]; then
            case "$TYPE" in
                $env_LOG_TYPE_CRIT)
                    logger -t $ORIGIN -p crit "$MESSAGE"
                   ;;
                $env_LOG_TYPE_EROR)
                    logger -t $ORIGIN -p err "$MESSAGE"
                    ;;
                $env_LOG_TYPE_WARN)
                    logger -t $ORIGIN -p warning "$MESSAGE"
                    ;;
                $env_LOG_TYPE_DEBG)
                    if [[ $LOG_LEVEL_DEBUG -le $MSG_LEVEL && $LOG_LEVEL_DEBUG -gt 0 ]]; then
                        logger -t $ORIGIN -p debug "$MESSAGE";
                    fi
                    ;;
                $env_LOG_TYPE_NOTC)
                    logger -t $ORIGIN -p notice "$MESSAGE"
                    ;;
                $env_LOG_TYPE_INFO)
                    logger -t $ORIGIN -p info "$MESSAGE"
                    ;;
                $env_LOG_TYPE_SUCS)
                    logger -t $ORIGIN -p info "$MESSAGE"
                    ;;

                *)
                    logger -t $ORIGIN "$MESSAGE"
                    ;;
            esac
    fi

}

#
# function for logging.
#
# examples:
# 	logger::log "TYPE" "MESSAGE"
# 	logger::log --type="ERROR" --msg="MESSAGE"
# 	logger::log "TYPE" "MESSAGE" --console=0
#
# named arguments
# --type		type WARNING, ERROR, INFO, CRITICAL, DEBUG, NOTICE
# --msg			message (default level is 0 = log always)
# --level		log level / log priority
# --timestamp		custom timestamp, preferably in the format %Y-%m-%d %H:%M:%S
# --log			enable logging to file using a value >0 if 0, logging it file if off.
# --console		set output to console on (>0) or off(0)
# --syslog		write logline to syslog if set to a value >0, if 0 then off.
#
# flags
# --echooff		disable log to console, LOG_LEVEL_CONSOLE = 0
# --echoon              enable log to console, LOG_LEVEL_CONSOLE = 999
# --logoff              disable log to logfile, LOG_LEVEL_FILE = 0
# --logoon		enable log to logfile, LOG_LEVEL_FILE = 999
#
logger::log(){

    local TYPE                  # type of message to log ( always parameter $1 or named arguemnt --type )
    local MESSAGE               # message to log ( always parameter $2 or named argument --msg )
    local MSG_LEVEL=0           # level (priority) of the message ( named parameter : --level= )
    local LOG_LEVEL_DEBUGL=0    # current message priority level ( debug level ) of the application ( named parameter : --syslevel= )
    local LOG_LEVEL_CONSOLE=999 # echo_on is set by argument console. >0 is enabled, if 0 console output (echo) is off. ( named parameter : console=, or flag --echoon or --echooff or --silent)
    local LOG_LEVEL_SYSLOG=999  # log to syslog if > 0 (1 or more) otherwise don't log to syslog.
    local LOG_LEVEL_FILE=999    # disable logging with named argument --log. If --log=false or 0, all logging is off, true or >0 logging is on.
    local TIMESTAMP             # timestamp ( named parameter timestamp of format %Y-%m-%d %H:%M:%S )
    local LOG_FILE	        # LOGFILE name fetched from global heap $LOG_FILE or from setting --logfile
    local -A ARGUMENTS          # Define array for argument list.

    # parse function arguments.
    logger::parse_function_args ARGUMENTS "$@"

    # set log line timestamp
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

    # copy generel log file setting from global heap
    if [[ -v env_LOG_FILE ]]; then LOG_FILE=$env_LOG_FILE; fi
    if [[ -v env_LOG_LEVEL_CONSOLE ]]; then LOG_LEVEL_CONSOLE=$env_LOG_LEVEL_CONSOLE; fi
    if [[ -v env_LOG_LEVEL_DEBUG ]]; then LOG_LEVEL_DEBUG=$env_LOG_LEVEL_DEBUG; fi
    if [[ -v env_LOG_LEVEL_FILE ]]; then LOG_LEVEL_FILE=$env_LOG_LEVEL_FILE; fi
    if [[ -v env_LOG_LEVEL_SYSLOG ]]; then LOG_LEVEL_SYSLOG=$env_LOG_LEVEL_SYSLOG; fi

    # handle required arguments.
    if [[ -v ARGUMENTS[1] ]]; then TYPE=${ARGUMENTS[1]}; fi
    if [[ -v ARGUMENTS[2] ]]; then MESSAGE=${ARGUMENTS[2]}; fi
    if [[ -v ARGUMENTS[msg] ]]; then MESSAGE=${ARGUMENTS[msg]}; fi
    if [[ -v ARGUMENTS[type] ]]; then TYPE=${ARGUMENTS[type]}; fi
    if [[ -v ARGUMENTS[level] ]]; then MSG_LEVEL=${ARGUMENTS[level]}; fi
    if [[ -v ARGUMENTS[logfile] ]]; then LOG_FILE=${ARGUMENTS[logfile]}; fi

    # handle extra arguments
    if [[ -v ARGUMENTS[echoon] ]]; then LOG_LEVEL_CONSOLE=999; fi
    if [[ -v ARGUMENTS[echooff] ]]; then LOG_LEVEL_CONSOLE=0; fi
    if [[ -v ARGUMENTS[consolon] ]]; then LOG_LEVEL_CONSOLE=999; fi
    if [[ -v ARGUMENTS[consoloff] ]]; then LOG_LEVEL_CONSOLE=0; fi
    if [[ -v ARGUMENTS[console] ]]; then LOG_LEVEL_CONSOLE=${ARGUMENTS[output]}; fi
    if [[ -v ARGUMENTS[log] ]]; then LOG_LEVEL_FILE=${ARGUMENTS[log]}; fi
    if [[ -v ARGUMENTS[logon] ]]; then LOG_LEVEL_FILE=999; fi
    if [[ -v ARGUMENTS[logoff] ]]; then LOG_LEVEL_FILE=0; fi
    if [[ -v ARGUMENTS[syslog] ]]; then LOG_LEVEL_SYSLOG=${ARGUMENTS[log]}; fi
    if [[ -v ARGUMENTS[syslogon] ]]; then LOG_LEVEL_SYSLOG=999; fi
    if [[ -v ARGUMENTS[syslogoff] ]]; then LOG_LEVEL_SYSLOG=0; fi
    if [[ -v ARGUMENTS[timestamp] ]]; then TIMESTAMP=${ARGUMENTS[timestamp]}; fi

    # disable logging to file if LOGFILE does not exist.
    if [[ "${LOG_FILE}" == "" ]]; then LOG_LEVEL_FILE=0; fi;

    # notify unknown if TYPE and MESSAGE are missing.
    if [[ "$TYPE" == "" ]]; then TYPE="unknown"; fi
    if [[ "$MESSAGE" == "" ]]; then MESSAGE="unknown"; fi

    MTYPE="$(logger::get_message_type "$TYPE")"

    # Write to console
    logger::log_to_console "$MTYPE" "$MESSAGE" "$TIMESTAMP" $LOG_LEVEL_CONSOLE $MSG_LEVEL $LOG_LEVEL_DEBUG

    # Write to file
    logger::log_to_file "$MTYPE" "$MESSAGE" "$TIMESTAMP" $LOG_LEVEL_FILE $MSG_LEVEL $LOG_LEVEL_DEBUG "$LOG_FILE"

    # Write to syslog
    logger::log_to_syslog "$MTYPE" "$MESSAGE" "$TIMESTAMP" $LOG_LEVEL_SYSLOG $MSG_LEVEL $LOG_LEVEL_DEBUG "$env_PROCESS_NAME"

}

# CRITICAL specific logger.
#
logger::log_critical(){
   logger::log "$env_LOG_TYPE_CRIT" "$@"
}

# ERROR specific logger.
#
logger::log_error(){
   logger::log "$env_LOG_TYPE_EROR" "$@"
}

# WARNING specific logger.
#
logger::log_warning(){
   logger::log "$env_LOG_TYPE_WARN" "$@"
}

# INFO specific logger.
#
logger::log_info(){
   logger::log "$env_LOG_TYPE_INFO" "$@"
}

# NOTICE specific logger.
#
logger::log_notice(){
   logger::log "$env_LOG_TYPE_NOTC" "$@"
}

# DEBUG specific logger.
#
logger::log_debug(){
   logger::log "$env_LOG_TYPE_DEBG" "$@"
}

# SUCCESS specific logger.
#
logger::log_success(){
   logger::log "$env_LOG_TYPE_SUCS" "$@"
}
