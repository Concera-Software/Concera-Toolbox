# Concera Toolbox

## Why toolbox?
A set of command line tools, libraries and installers we created to manage, update and install servers in a more rappid and easy way. Tools that can be used by less experienced users and in compbination can install applications in any way.

The toolbox is created using the online community, AI and our own skills. 

## License.
No license, mayby GPL but for now juist use the tools, change them, improve them, let us know about improvements so we can fix and improve the tools for everybody that uses them. 

## Compatibility
We tested this scripts and tools on with:
- Debian 13
- Debian 12
- Ubuntu 26.04LTS
- Ubuntu 24.04LTS

Older editions of Linux that the tools ware initially used on but are no longer maintained.
- Ubuntu 22.04LTS (not prefferred)

# Uniform implementation

To preserve the unity of very script and library file we need to commit to some standards:

## HEADER

Every file has an header with the following content:

```
#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
#
# Set of general bash functions for use in Bash scripts
#
# Version : v1.0.2
# Author  : André Hagoort
# Date    : 2026-05-19T20:48
#
# ----------------------------------------------------------------------------------------------------------------
# FUNCTIONS/METHODS
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
#
# ----------------------------------------------------------------------------------------------------------------
# DEPENDENCIES
#
# no dependencies in LIB_DEPENDENCIERS()
#
# ----------------------------------------------------------------------------------------------------------------
# USABLE GLOBAL ENV VARIABLES // 
#
# Globel (.env) variables. The env variables with the asterisk are mandatory to create before using the library
# IF needed, env_ variables are added (created), if they don't exist , to the GLOBAL scope.
#
# env_LOG_LEVEL_CONSOLE
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
# CHANGELOG
#
# 2026-05-20 | AH  | v1.0.2      | Added colors to console messages.
# 2026-05-20 | AH  | v1.0.1      | Fixed an issue with message levels preventing messages to be handled correctly.
# 2026-05-20 | AH  | v1.0.0      | Finalized and documented first version
# 2026-05-19 | AH  | v1.0.0-rc01 | First Release Candate
#
```

## LIBRARY FILES

Library files are stored in the /libs folder of the toolbox and seperated by "language" like bash, sh, php and 
phython. Every language has it's own folder. 

### BASH

Library files have a number of mandatory implementation requirements, whe using the include functions from the
core library like in

#### Use the LIB_REGISTER Array
Include registration for inclusion and dependencies. The LIB_REGISTER files is used by the toolbox-core library
file that handles loading libraries using core::load_library() for a single library file and and core::load_libraries()
for a library folder. By checking the LIB_REGISTER double inclusions are prevented and dependencies can be 
included automaticly or mually by calling core::load_dependencies()

if the library does not add its own library to the array, loading the library is assumed to be failed.

for every library two key's are created under it's own name: 

::version	string
::dependencies	array

```
# append file to LIB_REGISTER
if ! declare -p LIB_REGISTER >/dev/null 2>&1; then declare -gA LIB_REGISTER; fi
LIB_REGISTER["bashlib-logging.sh:version"]="v1.0.0"

# register dependencies of libraries in the toolbox. Multiple dependencies need to be space seperated.
LIB_REGISTER["bashlib-logging.sh:dependencies"]="bashlib-core.sh"
)
```

#### Append required environmental variables with default values if they don't exist

Libraries can use global configuration variables. These variables start with env_ pointing to the fact
they are set in the normal .env configuration file for scripts. These .env files are common for bash
bashed scripts.

```
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

if [[ ! -v env_LOG_TYPE_CRIT_COLOR ]]; then declare -g env_LOG_TYPE_CRIT_COLOR='\033[1;37;41m'; fi
if [[ ! -v env_LOG_TYPE_EROR_COLOR ]]; then declare -g env_LOG_TYPE_EROR_COLOR='\033[0;31m'; fi
if [[ ! -v env_LOG_TYPE_WARN_COLOR ]]; then declare -g env_LOG_TYPE_WARN_COLOR='\033[1;33m'; fi
if [[ ! -v env_LOG_TYPE_INFO_COLOR ]]; then declare -g env_LOG_TYPE_INFO_COLOR='\033[0;90m'; fi
if [[ ! -v env_LOG_TYPE_NOTC_COLOR ]]; then declare -g env_LOG_TYPE_NOTC_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_DEBG_COLOR ]]; then declare -g env_LOG_TYPE_DEBG_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_UNKN_COLOR ]]; then declare -g env_LOG_TYPE_UNKN_COLOR='\033[1;37m'; fi
if [[ ! -v env_LOG_TYPE_SUCS_COLOR ]]; then declare -g env_LOG_TYPE_SUCS_COLOR='\033[1;37m'; fi
if [[ ! -v env_COLOR_RESET ]]; then declare -g env_COLOR_RESET='\033[1;37m'; fi
```

