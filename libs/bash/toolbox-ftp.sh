#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# Set of general bash functions for use in Bash scripts
#
# Version : v1.0
# Author  : André Hagoort
# Date    : 2026-05-19
#
# ---------------------------------------------------------------------------------------
# Function List
# log $type $message $level
#
# ---------------------------------------------------------------------------------------
#
# DEPENDENCIES
#
# bashlib-logger.sh
#
# ---------------------------------------------------------------------------------------
# Changelog / History :
# 2026-05-19 - AH - First Release Candate
#

if ! declare -p LIB_REGISTER >/dev/null 2>&1; then declare -gA LIB_REGISTER; fi
LIB_REGISTER["bashlib-ftp.sh"]="ok";

# check dependencies.
#
ftp::check_dependencies() {

}

# check dependencies on load.
ftp::check_dependencies


# ---------------------------------------------------------------------------------------
# FTP FUNCTION to CHECK IF FILE EXISTS ON FTP SERVER
# ---------------------------------------------------------------------------------------
#
ftp::ftp_file_exists() {

    local REMOTE_FILE="$1"
    local FTP_HOST="$2"
    local FTP_USER="$3"
    local FTP_PASS="$4"

    log "INFO" "ftp_file_exists( $REMOTE_FILE, $FTP_HOST, $FTP_USER, $FTP_PASS )"

    lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF >/dev/null 2>&1
set ftp:passive-mode true
set ftp:ssl-allow no
cat "$REMOTE_FILE"
bye
EOF
}

