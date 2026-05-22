\# Concera Toolbox

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
#  ___   _   ___ _  _ _    ___ ___   _                   _
# | _ ) /_\ / __| || | |  |_ _| _ ) | |   ___  __ _ __ _(_)_ _  __ _
# | _ \/ _ \\__ \ __ | |__ | || _ \ | |__/ _ \/ _` / _` | | ' \/ _` |
# |___/_/ \_\___/_||_|____|___|___/ |____\___/\__, \__, |_|_||_\__, |
#                                             |___/|___/       |___/
# Created by Concera.
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
