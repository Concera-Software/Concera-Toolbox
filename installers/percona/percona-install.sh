#!/usr/bin/env bash
#
#  _____ ___   ___  _    ___ _    ___   ___ ___ 
# |_   _/ _ \ / _ \| |  | _ ) |  / _ \ / __/ __|
#   | || (_) | (_) | |__| _ \ |_| (_) | (__\__ \
#   |_| \___/ \___/|____|___/____\___/ \___|___/
#
#
# This script installs or upgrades Percona Server on supported Debian/Ubuntu
# systems.
#
# Supported systems:
#   - Ubuntu 22.04 LTS
#   - Ubuntu 24.04 LTS
#   - Ubuntu 26.04 LTS
#   - Debian 12
#   - Debian 13
#
# Example usage:
#
#   sudo ./install-percona.sh
#
# Force replacement of existing MySQL:
#
#   sudo ./install-percona.sh --force-replace-mysql
#
# Force upgrade of existing Percona:
#
#   sudo ./install-percona.sh --force-upgrade-percona
#
# Install PHP MySQL support if missing:
#
#   sudo ./install-percona.sh --install-php-support
#
# Full automatic mode:
#
#   sudo ./install-percona.sh \
#     --force-replace-mysql \
#     --force-upgrade-percona \
#     --install-php-support
#
#
###############################################################################

set -Eeuo pipefail

###############################################################################
# Exit codes
#
# These allow other scripts or monitoring tools to see what happened.
###############################################################################

EXIT_SUCCESS=0
EXIT_NOT_ROOT=5
EXIT_NO_CONFIG=6
EXIT_ENV_ERROR=7
EXIT_UNSUPPORTED_OS=10
EXIT_USER_ABORT=15
EXIT_PREREQUISITES=20
EXIT_REPO_SETUP=30
EXIT_INSTALL=40
EXIT_SERVICE=50
EXIT_VERIFY=60
EXIT_UNKNOWN=99

###############################################################################
# Default settings
###############################################################################

PERCONA_REPO="ps-84-lts"

FORCE_REPLACE_MYSQL=0
FORCE_UPGRADE_PERCONA=0
INSTALL_PHP_SUPPORT=0
SILENT=0
DEBUG=0
DB_TEST=1 #(default off)
DB_USR="root"
DB_PWD="root"
DB_HOST="127.0.0.1"
LOG_FILE=""
LOG_FILE_EXISTS=0
ENV_FILE=".env"

###############################################################################
# Helper functions
###############################################################################


log_init(){

  local FILE=$LOG_FILE

  # check if arguments do exists
  if [[ $# -ge 1 ]]; then
    if [[  -n "$1" ]]; then
      FILE=${1};
    fi
  fi

  # try to create the file if it does not exist.
  #
  if [[ -n "${FILE}" && ! -f "${FILE}" ]]; then
    touch ${LOG_FILE}
  fi

  # test the availability of the logfile.
  #
  if [[ -f "${FILE}" ]]; then
      LOG_FILE_EXISTS=1
      return 0
  fi

  LOG_FILE_EXISTS=0
  # return eror if file is not available.
  return 1

}

log() {
  if [[ "$SILENT" -ne 1 ]]; then
    printf '[%s] [INFO] %s\n' "$(date '+%F %T')" "$*"
  fi

  if (( LOG_FILE_EXISTS )); then echo "[$(date '+%F %T')] [INFO] $*" >> $LOG_FILE; fi

  logger -p info "$*"
}

log_success(){
  if [[ "$SILENT" -ne 1 ]]; then
    printf '[%s] [SUCS] %s\n' "$(date '+%F %T')" "$*"
  fi

  if (( LOG_FILE_EXISTS )); then printf '[%s] [SUCS] %s\n' "$(date '+%F %T')" "$*" >> $LOG_FILE; fi

  logger -p notice "$*"
}

log_warning(){
  if [[ "$SILENT" -ne 1 ]]; then
    printf '[%s] [WARN] %s\n' "$(date '+%F %T')" "$*"
  fi

  if (( LOG_FILE_EXISTS )); then printf '[%s] [WARN] %s\n' "$(date '+%F %T')" "$*" >> $LOG_FILE; fi

  logger -p warning "$*"
}

log_error(){
  if [[ "$SILENT" -ne 1 ]]; then
    printf '[%s] [EROR] %s\n' "$(date '+%F %T')" "$*"
  fi

  if (( LOG_FILE_EXISTS )); then printf '[%s] [EROR] %s\n' "$(date '+%F %T')" "$*" >> $LOG_FILE; fi

  logger -p error "$*"
}

fail() {
  local message="$1"
  local code="${2:-$EXIT_UNKNOWN}"

  if [[ "$SILENT" -ne 1 ]]; then
    echo
    echo "ERROR: $message" >&2
  fi

  exit "$code"
}

usage() {
  echo "  _____ ___   ___  _    ___ _    ___   ___ ___ "
  echo " |_   _/ _ \ / _ \| |  | _ ) |  / _ \ / __/ __|"
  echo "   | || (_) | (_) | |__| _ \ |_| (_) | (__\\__ \\"
  echo "   |_| \___/ \___/|____|___/____\___/ \___|___/"
  echo ""
  echo " PERCONA INSTALLER v1.0.0-rc01"

  cat <<EOF

-----------------------------------------------------------------------------------------

Usage:
  sudo $0 [options]

Options:
  --force-replace-mysql    Replace existing Oracle/MySQL without asking
  --force-upgrade-percona  Upgrade existing Percona without asking
  --install-php-support    Install PHP MySQL support if missing
  --silent                 Print no output; only return exit code
  --debug                  Print all command output for troubleshooting
  --no-test-connection     Don't test the database connection (default)
  --test-connection	   Test the database connection
  --dbuser		   Database user ( root is default )
  --dbpasswd		   Database password ( password required on new installations )
  --dbhost		   Database host ( 127.0.0.1 is default )
  --logfile		   Logfile to use for install logs.
  --env			   Config (.env) file
  -h, --help               Show this help

Exit codes:
  0   success
  5   script not run as root
  6   missing configuration / argument
  10  unsupported OS
  15  user aborted
  20  prerequisite failure
  30  repository setup failure
  40  install/upgrade failure
  50  service failure
  60  verification failure
  99  unknown error

-----------------------------------------------------------------------------------------

EOF
}

ask_yes_no() {
  local question="$1"
  local answer

  while true; do
    read -r -p "$question [y/N]: " answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO|"") return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

php_mysql_support_ok() {
  command -v php >/dev/null 2>&1 || return 1

  php -m 2>/dev/null | grep -qi '^mysqli$' &&
  php -m 2>/dev/null | grep -qi '^pdo_mysql$'
}

run_cmd() {
  if [[ "$DEBUG" -eq 1 && "$SILENT" -ne 1 ]]; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

set_mysql_root_password() {
  if [[ "$DB_PWD" -ne 1 ]]; then
    return 0
  fi

  if [[ -z "$DB_PWD" ]]; then
    fail "Password option used, but password is empty" "$EXIT_VERIFY"
  fi

  if [[ -z "$DB_USR" ]]; then
    fail "No (root) user configured for database" "$EXIT_VERIFY"
  fi

  log "Setting MySQL root user and password for $DB_USR@localhost using password $DB_PWD"

  DBHOST=""
  if [[ "$DB_HOST" != "" ]]; then
     DBHOST=" -h${DB_HOST}"
  fi

  mysql ${DBHOS} <<SQL
ALTER USER '${DB_USR}'@'localhost'
IDENTIFIED WITH caching_sha2_password BY '${DB_PWD}';

FLUSH PRIVILEGES;
SQL

  mysql ${DBHOST}-u${DB_USR} -p"${DB_PWD}" -e "SELECT 1;" >/dev/null 2>&1 \
    || fail "Root password for user $DB_USR was set but login verification failed" "$EXIT_VERIFY"

  log "MySQL root, using user $DB_USR, password verified"
}

###############################################################################
# Read command-line arguments
###############################################################################

while [[ $# -gt 0 ]]; do
  ARG=$1
  case "$ARG" in
    --force-replace-mysql)
      FORCE_REPLACE_MYSQL=1
      shift
      ;;

    --force-upgrade-percona)
      FORCE_UPGRADE_PERCONA=1
      shift
      ;;

    --install-php-support)
      INSTALL_PHP_SUPPORT=1
      shift
      ;;
    --force-all)
      FORCE_REPLACE_MYSQL=1
      FORCE_UPGRADE_PERCONA=1
      INSTALL_PHP_SUPPORT=1
      shift
      ;;
    --silent)
      SILENT=1
      shift
      ;;
    --debug)
      DEBUG=1
      shift
      ;;
    --no-test-connection)
      DB_TEST=2
      shift
      ;;
    --test-connection)
      DB_TEST=1
      shift
      ;;
    --dbuser=*)
      DB_USR="${ARG#*=}"
      log "Use user from argument --dbuser"
      shift
      ;;
    --dbpasswd=*)
      DB_PWD="${ARG#*=}"
      log "Use password from argument --dbpasswd"
      shift
      ;;
    --dbhost=*)
      DB_HOST="${ARG#*=}"
      shift
      ;;
    --env=*)
      ENV_FILE="${ARG#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit "$EXIT_SUCCESS"
      ;;

    *)
      usage
      fail "Unknown argument: $1" "$EXIT_UNKNOWN"
      ;;
  esac
done

log "running INSTALLING / UPGRADING PERCONA"
if ! log_init; then
   log_error "Failed to create logfile"
fi

# check for valid configuration
if [[ -n "$ENV_FILE" ]]; then
   if [[ -f "$ENV_FILE" ]]; then
       source $ENV_FILE
   elif [[ "$ENV_FILE" != ".env" ]]; then
       fail "Configuration file $ENV_FILE does not exist" "$EXIT_ENV_ERROR"
   fi
fi

# check for database settings.
if [[ ! -n "$DB_USR" ]]; then
    fail "Database user not set"
    usage
    exit "${EXIT_NO_CONFIG}"
fi
if [[ ! -n "$DB_PWD" ]]; then
    fail "Database password not set"
    usage
    exit "${EXIT_NO_CONFIG}"
fi


#if [[ $DEBUG -eq 0 || $SILENT -eq 1 ]]; then
   RUN_CMD="run_cmd "
#else
#   RUN_CMD=""
#fi

###############################################################################
# Check if script is running as root
###############################################################################

if [[ "${EUID}" -ne 0 ]]; then
  fail "This script must be run as root. Use sudo." "$EXIT_NOT_ROOT"
fi

###############################################################################
# Detect Linux distribution
###############################################################################

if [[ ! -f /etc/os-release ]]; then
  fail "/etc/os-release not found. Cannot detect Linux distribution." "$EXIT_UNSUPPORTED_OS"
fi

. /etc/os-release

OS_KEY="${ID}:${VERSION_ID}"
SUPPORTED_OS_REGEX='^(ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:12|debian:13)$'

if [[ ! "$OS_KEY" =~ $SUPPORTED_OS_REGEX ]]; then
  fail "Unsupported OS: ${PRETTY_NAME:-unknown}" "$EXIT_UNSUPPORTED_OS"
fi

log "Detected supported OS: ${PRETTY_NAME}"

###############################################################################
# Make apt non-interactive
###############################################################################

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export PERCONA_TELEMETRY_DISABLE=1

###############################################################################
# Detect existing MySQL or Percona installation
###############################################################################

MYSQL_INSTALLED=0
PERCONA_INSTALLED=0

if dpkg -l mysql-server 2>/dev/null | grep -q '^ii'; then
  MYSQL_INSTALLED=1
fi

if dpkg -l percona-server-server 2>/dev/null | grep -q '^ii'; then
  PERCONA_INSTALLED=1
fi

###############################################################################
# Ask before replacing MySQL, unless forced
###############################################################################

if [[ "$MYSQL_INSTALLED" -eq 1 && "$PERCONA_INSTALLED" -eq 0 ]]; then
  log "Existing MySQL installation detected."

  if [[ "$FORCE_REPLACE_MYSQL" -ne 1 ]]; then
    if ! ask_yes_no "Do you want to replace MySQL with Percona Server?"; then
      fail "User aborted MySQL replacement." "$EXIT_USER_ABORT"
    fi
  else
    log "Force replace MySQL option enabled."
  fi
fi

###############################################################################
# Ask before upgrading Percona, unless forced
###############################################################################

if [[ "$PERCONA_INSTALLED" -eq 1 ]]; then
  CURRENT_VERSION="$(dpkg-query -W -f='${Version}' percona-server-server 2>/dev/null || true)"
  log "Existing Percona Server detected: ${CURRENT_VERSION:-unknown version}"

  if [[ "$FORCE_UPGRADE_PERCONA" -ne 1 ]]; then
    if ! ask_yes_no "Do you want to upgrade Percona Server?"; then
      fail "User aborted Percona upgrade." "$EXIT_USER_ABORT"
    fi
  else
    log "Force upgrade Percona option enabled."
  fi
fi

###############################################################################
# Install required tools
###############################################################################

log "Checking for interrupted dpkg state"

if [[ -f /var/lib/dpkg/updates/0000 ]] || [[ -n "$(ls -A /var/lib/dpkg/updates 2>/dev/null)" ]]; then
  log "dpkg appears interrupted. Running dpkg --configure -a"

  ${RUN_CMD}dpkg dpkg --configure -a \
       || fail "Failed to repair interrupted dpkg state" "$EXIT_PREREQUISITES"
fi

log "Fixing broken packages if needed"

${RUN_CMD}apt-get -f install -y \
  || fail "Failed to fix broken packages" "$EXIT_PREREQUISITES"


log "Updating package list"
${RUN_CMD}apt-get update || fail "apt update failed" "$EXIT_PREREQUISITES"


log "Installing required system packages"
${RUN_CMD}apt-get install -y \
  curl \
  ca-certificates \
  gnupg2 \
  lsb-release \
  apt-transport-https \
  || fail "Failed to install prerequisites" "$EXIT_PREREQUISITES"

###############################################################################
# Install Percona repository helper
###############################################################################

TMP_DEB="/tmp/percona-release_latest.generic_all.deb"

log "Downloading Percona repository package"
${RUN_CMD}curl -fsSL \
  -o "$TMP_DEB" \
  "https://repo.percona.com/apt/percona-release_latest.generic_all.deb" \
  || fail "Failed to download Percona repository package" "$EXIT_REPO_SETUP"

log "Installing Percona repository package"
${RUN_CMD}apt-get install -y "$TMP_DEB" \
  || fail "Failed to install Percona repository package" "$EXIT_REPO_SETUP"

rm -f "$TMP_DEB"

###############################################################################
# Enable Percona Server repository
###############################################################################

log "Enabling Percona repository: $PERCONA_REPO"
${RUN_CMD}percona-release setup -y "$PERCONA_REPO" --scheme https \
  || fail "Failed to configure Percona repository" "$EXIT_REPO_SETUP"

log "Updating package list after enabling Percona repository"
${RUN_CMD}apt-get update || fail "apt update after Percona repo setup failed" "$EXIT_REPO_SETUP"

###############################################################################
# Check available Percona package version
###############################################################################

CANDIDATE="$(apt-cache policy percona-server-server | awk '/Candidate:/ {print $2}')"

if [[ -z "$CANDIDATE" || "$CANDIDATE" == "(none)" ]]; then
  fail "No Percona Server package candidate found" "$EXIT_REPO_SETUP"
fi

log "Latest available Percona package candidate: $CANDIDATE"

###############################################################################
# Install or upgrade Percona Server
###############################################################################

if [[ "$PERCONA_INSTALLED" -eq 1 ]]; then
  log "Upgrading Percona Server"
else
  log "Installing Percona Server"
fi

${RUN_CMD}apt-get install -y \
  percona-server-server \
  percona-server-client \
  || fail "Percona Server installation or upgrade failed" "$EXIT_INSTALL"

###############################################################################
# Optional PHP support
###############################################################################

if [[ "$INSTALL_PHP_SUPPORT" -eq 1 ]]; then
  log "Checking PHP MySQL support"

  if php_mysql_support_ok; then
    log "PHP MySQL support is already installed and working"
  else
    log "Installing PHP MySQL support"

    ${RUN_CMD}apt-get install -y php-mysql \
      || fail "Failed to install PHP MySQL support" "$EXIT_INSTALL"

    ${RUN_CMD}systemctl reload apache2 2>/dev/null || true
    ${RUN_CMD}systemctl reload php*-fpm 2>/dev/null || true

    php_mysql_support_ok \
      || fail "PHP MySQL extensions are not loaded after installation" "$EXIT_VERIFY"

    log "PHP MySQL support installed and verified"
  fi
fi

###############################################################################
# Enable and restart database service
###############################################################################

log "Enabling mysql service"
${RUN_CMD}systemctl enable mysql || fail "Failed to enable mysql service" "$EXIT_SERVICE"

log "Restarting mysql service"
${RUN_CMD}systemctl restart mysql || fail "Failed to restart mysql service" "$EXIT_SERVICE"

###############################################################################
# Verify service is running
###############################################################################

log "Checking if mysql service is active"

${RUN_CMD} systemctl is-active --quiet mysql || {
  systemctl status mysql --no-pager || true
  fail "mysql service is not active" "$EXIT_SERVICE"
}

###############################################################################
# Build database connection options
###############################################################################

DB_CONNECT=()

if [[ -n "$DB_HOST" ]]; then
  DB_CONNECT+=("-h${DB_HOST}")
fi

if [[ -n "$DB_USR" ]]; then
  DB_CONNECT+=("-u${DB_USR}")
fi

if [[ -n "$DB_PWD" ]]; then
  DB_CONNECT+=("-p${DB_PWD}")
fi

###############################################################################
# Verify database responds
###############################################################################

log "Checking database availability"

${RUN_CMD} mysqladmin "${DB_CONNECT[@]}" ping \
  || fail "mysqladmin ping failed" "$EXIT_VERIFY"

if [[ "$PERCONA_INSTALLED" -eq 0 ]]; then
  set_mysql_root_password
fi

if [[ "$DB_TEST" -eq 1 ]]; then

  log "Testing database login"

  ${RUN_CMD}mysql "${DB_CONNECT[@]}" -NBe "SELECT 1;" >/dev/null 2>&1 \
    || fail "Could not login as defined user $DB_USR" "$EXIT_VERIFY"

  log "Querying Percona version"

  VERSION_INFO="$(mysql "${DB_CONNECT[@]}" -NBe "SELECT @@version, @@version_comment;" 2>/dev/null)" \
    || fail "Could not query server version" "$EXIT_VERIFY"

  echo "$VERSION_INFO" | grep -qi percona \
    || fail "Server is running but does not identify as Percona: $VERSION_INFO" "$EXIT_VERIFY"

  log "Percona server version installed: $VERSION_INFO"

  log "Running database read/write verification"

  ${RUN_CMD}mysql "${DB_CONNECT[@]}" <<'SQL' >/dev/null
CREATE DATABASE IF NOT EXISTS percona_installer_verify;

CREATE TABLE IF NOT EXISTS percona_installer_verify.t (
  id INT PRIMARY KEY,
  msg VARCHAR(32) NOT NULL
);

REPLACE INTO percona_installer_verify.t VALUES (1, 'ok');

SELECT * FROM percona_installer_verify.t WHERE id = 1;

DROP DATABASE percona_installer_verify;
SQL

else
  log "Skipped database connection test"
fi

FINAL_VERSION="unknown"

if [[ -n "$DB_USR" && -n "$DB_PWD" ]]; then
  FINAL_VERSION="$(mysql "${DB_CONNECT[@]}" -NBe "SELECT CONCAT(@@version, ' - ', @@version_comment);" 2>/dev/null || echo unknown)"
  log "Percona version installed: $FINAL_VERSION"
fi

log_success "Percona Server is installed/upgraded and operational."
log "Running version: $FINAL_VERSION"

exit "$EXIT_SUCCESS"
