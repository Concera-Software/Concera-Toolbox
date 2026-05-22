#!/bin/bash
#   ___ ___  _  _  ___ ___ ___    _     _____ ___   ___  _    ___  _____  __
#  / __/ _ \| \| |/ __| __| _ \  /_\   |_   _/ _ \ / _ \| |  | _ )/ _ \ \/ /
# | (_| (_) | .` | (__| _||   / / _ \    | || (_) | (_) | |__| _ \ (_) >  <
#  \___\___/|_|\_|\___|___|_|_\/_/ \_\   |_| \___/ \___/|____|___/\___/_/\_\
#
# https://github.com/Concera-Software/Concera-Toolbox
#
# PHP switch version for CLI or APACHE
# ----------------------------------------------------------------------------------------------------------------
#
# Version : v1.0.2
# Author  : S. van Buren
# Date    : 2026-05-22
#
# ----------------------------------------------------------------------------------------------------------------
# DESCRIPTION:
#
# This file can be used to change/switch between installed PHP versions on a system (tested on
# Debian 12). This script supports targeting the CLI  environment, the Apache web server web engine,
# or both. (default). It also includes automated configuration syntax checks for PHP-FPM and Apache,
# with an instant rollback mechanism on failure to prevent webserver downtime.
#
# Use `./switch-php-version.sh -h` for more details. Some example commands:
#
# `./switch-php-version.sh 8.5 php-fpm`		Quick switch to 8.5 using PHP-FPM
# `./switch-php-version.sh 8.3 mod_php`		Quick switch to 8.3 using Apache Module
# `./switch-php-version.sh 8.4 --dry-run`	Test switching to 8.4 safely
# `./switch-php-version.sh`			Starts interactive wizard
#

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: This script must be run as root (via sudo)."
  exit 1
fi

# Ensure /usr/sbin and /sbin are in the PATH (critical for Debian 12 via sudo)
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Detect available PHP versions in /etc/php/
VERSIONS=($(ls -d /etc/php/* 2>/dev/null | awk -F/ '{print $4}' | grep -E '^[0-9]+\.[0-9]+$' | sort -V))

if [ ${#VERSIONS[@]} -eq 0 ]; then
  echo "[-] Error: No PHP versions found in /etc/php/"
  exit 1
fi

# Capture initial state for rollback purposes and startup overview
PREVIOUS_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null)
PREVIOUS_MOD=$(ls /etc/apache2/mods-enabled/php*.load 2>/dev/null | awk -F/ '{print $5}' | sed 's/.load//')
PREVIOUS_CONF=$(ls /etc/apache2/conf-enabled/php*-fpm.conf 2>/dev/null | awk -F/ '{print $5}' | sed 's/.conf//')

# === CURRENT STATUS OVERVIEW ===
echo "========================================================"
echo "                CURRENT PHP CONFIGURATION               "
echo "========================================================"
if [ ! -z "$PREVIOUS_VERSION" ]; then
  echo "  [*] Active CLI Instance (Terminal):  PHP $PREVIOUS_VERSION"
else
  echo "  [-] Active CLI Instance (Terminal):  Not detected"
fi

if [ ! -z "$PREVIOUS_CONF" ]; then
  echo "  [*] Loaded Apache Driver:            PHP-FPM ($PREVIOUS_CONF)"
elif [ ! -z "$PREVIOUS_MOD" ]; then
  echo "  [*] Loaded Apache Driver:            Apache Module ($PREVIOUS_MOD)"
else
  echo "  [-] Loaded Apache Driver:            No active PHP driver found"
fi
echo "========================================================"
echo ""

# Function to display help instructions
show_help() {
  echo "Usage: sudo $0 [OPTIONS] [PHP-VERSION] [MODE]"
  echo ""
  echo "A helper utility for Debian 12 to easily switch between PHP versions"
  echo "for both CLI (Terminal) and Apache web server."
  echo ""
  echo "Options:"
  echo "  -h, --help            Show this help message and exit."
  echo "  -d, --dry-run         Simulate the execution without making changes."
  echo "  -v, --version=VERSION Directly switch to the specified PHP version."
  echo "  -m, --mode=MODE       Explicitly set Apache handler mode: 'fpm', 'mod_php', or 'auto'."
  echo "  -t, --target=TARGET   Target environment: 'cli', 'apache', or 'both'."
  echo ""
  echo "Examples (Short syntax):"
  echo "  sudo $0 8.5 php-fpm        -> Quick switch to 8.5 using PHP-FPM (both CLI & Apache)"
  echo "  sudo $0 8.3 mod_php cli    -> Quick switch to 8.3 Apache Module, but target CLI only"
  echo "  sudo $0 --version=8.4 --target=apache -> Switch Apache only to 8.4"
  echo "  sudo $0                    -> Starts interactive wizard"
  echo ""
  echo "Installed versions on this machine: ${VERSIONS[*]}"
  echo ""
}

TARGET_VERSION=""
RAW_MODE=""
MODE="" 
RAW_TARGET=""
DRY_RUN=false
TARGET_CLI=true
TARGET_APACHE=true
EXECUTE_ROLLBACK=false

# === PARSE CLI ARGUMENTS ===
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --version=*)
      TARGET_VERSION="${1#*=}"
      shift
      ;;
    -v|--version)
      TARGET_VERSION="$2"
      shift 2
      ;;
    --mode=*)
      RAW_MODE="${1#*=}"
      shift
      ;;
    -m|--mode)
      RAW_MODE="$2"
      shift 2
      ;;
    --target=*)
      RAW_TARGET="${1#*=}"
      shift
      ;;
    -t|--target)
      RAW_TARGET="$2"
      shift 2
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
        TARGET_VERSION="$1"
      elif [[ "$1" =~ ^(cli|apache|both)$ ]]; then
        RAW_TARGET="$1"
      else
        RAW_MODE="$1"
      fi
      shift
      ;;
  esac
done

# === HELPER EXECUTION FUNCTION (Handles Dry-Run logic) ===
run_cmd() {
  local description="$1"
  local cmd="$2"
  
  if [ "$DRY_RUN" = true ]; then
    echo -e "  \033[33m[DRY RUN]\033[0m Would execute: $description"
  else
    eval "$cmd"
  fi
}

# === INTERACTIVE VERSION MENU ===
select_version_menu() {
  echo "[+] Scanning for installed PHP versions..."
  echo ""
  echo "Available PHP Versions:"
  for i in "${!VERSIONS[@]}"; do
    echo "  $((i+1))) PHP ${VERSIONS[$i]}"
  done
  echo ""

  read -p "Select a version number (1-${#VERSIONS[@]}): " CHOICE

  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#VERSIONS[@]}" ]; then
    echo "[-] Error: Invalid input selection. Aborting."
    exit 1
  fi
  TARGET_VERSION="${VERSIONS[$((CHOICE-1))]}"
}

if [ "$DRY_RUN" = true ]; then
  echo -e "\033[33m[*] DRY RUN MODE ACTIVE. No permanent system changes will be written.\033[0m"
fi

# Determine version target first
if [ -z "$TARGET_VERSION" ]; then
  select_version_menu
fi

# === PROCESS OR PROMPT FOR TARGET ===
if [ ! -z "$RAW_TARGET" ]; then
  CLEAN_TARGET=$(echo "$RAW_TARGET" | tr '[:upper:]' '[:lower:]')
  case "$CLEAN_TARGET" in
    cli)
      TARGET_CLI=true
      TARGET_APACHE=false
      ;;
    apache|web)
      TARGET_CLI=false
      TARGET_APACHE=true
      ;;
    both)
      TARGET_CLI=true
      TARGET_APACHE=true
      ;;
    *)
      echo "[-] Error: Invalid target '$RAW_TARGET'. Choose from: cli, apache, or both."
      exit 1
      ;;
  esac
else
  # === INTERACTIVE COMPONENT TARGET MENU ===
  echo ""
  echo "Select which components to update to PHP $TARGET_VERSION:"
  echo "  1) Both CLI (Terminal) and Apache Web Server"
  echo "  2) CLI (Terminal) Only"
  echo "  3) Apache Web Server Only"
  echo ""
  read -p "Choose target component (1-3) [Default: 1]: " COMPONENT_CHOICE

  case "$COMPONENT_CHOICE" in
    2)
      TARGET_CLI=true
      TARGET_APACHE=false
      ;;
    3)
      TARGET_CLI=false
      TARGET_APACHE=true
      ;;
    *)
      TARGET_CLI=true
      TARGET_APACHE=true
      ;;
  esac
fi

# Loop for validation and recovery paths
while true; do
  VALID=false
  for v in "${VERSIONS[@]}"; do
    if [ "$v" == "$TARGET_VERSION" ]; then
      VALID=true
      break
    fi
  done

  if [ "$VALID" = false ]; then
    echo "[-] Error: PHP $TARGET_VERSION configuration structure not found."
    exit 1
  fi

  # === NORMALIZE HANDLER INPUT ===
  if [ "$TARGET_APACHE" = true ]; then
    if [ ! -z "$RAW_MODE" ]; then
      CLEAN_MODE=$(echo "$RAW_MODE" | tr '[:upper:]' '[:lower:]')
      
      if [ "$CLEAN_MODE" = "fpm" ] || [ "$CLEAN_MODE" = "php-fpm" ] || [ "$CLEAN_MODE" = "php_fpm" ]; then
        MODE="fpm"
      elif [ "$CLEAN_MODE" = "mod_php" ] || [ "$CLEAN_MODE" = "mod-php" ] || [ "$CLEAN_MODE" = "modphp" ]; then
        MODE="mod_php"
      elif [ "$CLEAN_MODE" = "auto" ]; then
        MODE="auto"
      else
        echo "[-] Error: Invalid mode '$RAW_MODE'. Choose from: fpm, mod_php, or auto"
        exit 1
      fi
    fi

    # === INTERACTIVE HANDLER MENU (DEFAULT TO FPM) ===
    if [ -z "$MODE" ]; then
      echo ""
      echo "Select Apache integration handler mode for PHP $TARGET_VERSION:"
      echo "  1) Automatic Detection"
      echo "  2) PHP-FPM (Highly Recommended)"
      echo "  3) Apache Module (mod_php)"
      echo ""
      read -p "Choose a handler setting (1-3) [Default: 2]: " MODE_CHOICE

      case "$MODE_CHOICE" in
        1) MODE="auto" ;;
        3) MODE="mod_php" ;;
        *) MODE="fpm" ;;
      esac
    fi

    # === MISSING PACKAGE SAFEGUARD ===
    if [ "$MODE" = "fpm" ] || [ "$MODE" = "auto" ]; then
      if [ ! -f "/etc/apache2/conf-available/php$TARGET_VERSION-fpm.conf" ] || [ ! -f "/usr/sbin/php-fpm$TARGET_VERSION" ]; then
        echo ""
        echo "[!] WARNING: PHP-FPM $TARGET_VERSION packages appear to be missing or incomplete!"
        
        if [ "$DRY_RUN" = true ]; then
          echo -e "  \033[33m[DRY RUN]\033[0m Missing packages detected. In real execution, apt prompt would appear here."
          break
        fi

        echo "    What would you like to do?"
        echo "      1) Attempt to install 'php$TARGET_VERSION-fpm' via apt now"
        echo "      2) Switch to Apache Module mode (mod_php) instead"
        echo "      3) Choose a different PHP version"
        echo "      4) Abort script"
        echo ""
        read -p "Select a recovery option (1-4): " RECOVERY_CHOICE

        case "$RECOVERY_CHOICE" in
          1)
            echo "[+] Updating apt package index..."
            apt-get update -y
            echo "[+] Installing php$TARGET_VERSION-fpm..."
            apt-get install -y "php$TARGET_VERSION-fpm"
            
            if [ -f "/etc/apache2/conf-available/php$TARGET_VERSION-fpm.conf" ]; then
              echo "[+] Installation successful!"
              break
            else
              echo "[-] Error: Installation completed but configuration files are still missing."
              MODE=""
              RAW_MODE=""
              continue
            fi
            ;;
          2)
            echo "[*] Switching execution target to mod_php..."
            MODE="mod_php"
            break
            ;;
          3)
            MODE=""
            RAW_MODE=""
            select_version_menu
            continue
            ;;
          *)
            echo "[-] Execution aborted by user."
            exit 1
            ;;
        esac
      fi
    fi
  fi
  break
done

echo ""
echo "[+] Initializing switch sequence to PHP $TARGET_VERSION (CLI: $TARGET_CLI, Apache: $TARGET_APACHE)"
echo "--------------------------------------------------------"

# 1. Update CLI (Only if CLI update is requested)
if [ "$TARGET_CLI" = true ]; then
  echo "[+] Configuring CLI subsystem binaries..."
  run_cmd "update-alternatives --set php /usr/bin/php$TARGET_VERSION" "update-alternatives --set php /usr/bin/php$TARGET_VERSION >/dev/null 2>&1"
  run_cmd "update-alternatives --set phar /usr/bin/phar$TARGET_VERSION" "update-alternatives --set phar /usr/bin/phar$TARGET_VERSION >/dev/null 2>&1"
  run_cmd "update-alternatives --set phar.phar /usr/bin/phar.phar$TARGET_VERSION" "update-alternatives --set phar.phar /usr/bin/phar.phar$TARGET_VERSION >/dev/null 2>&1"
fi

# 2. Process Apache adjustments (Only if Apache update is requested)
if [ "$TARGET_APACHE" = true ]; then
  # Process Apache Module changes (mod_php)
  if [ "$MODE" = "auto" ] || [ "$MODE" = "mod_php" ]; then
    echo "[+] Checking native Apache modules..."
    CURRENT_PHP_MODS=$(ls /etc/apache2/mods-enabled/php*.load 2>/dev/null | awk -F/ '{print $5}' | sed 's/.load//')

    if [ ! -z "$CURRENT_PHP_MODS" ]; then
      for old_mod in $CURRENT_PHP_MODS; do
        if [ "$old_mod" != "php$TARGET_VERSION" ]; then
          echo "[*] Disabling legacy Apache binary module: $old_mod"
          run_cmd "a2dismod $old_mod" "a2dismod $old_mod >/dev/null 2>&1"
        fi
      done
    fi

    if [ "$MODE" = "mod_php" ] || [ -f "/etc/apache2/mods-available/php$TARGET_VERSION.load" ]; then
      if [ -f "/etc/apache2/mods-available/php$TARGET_VERSION.load" ]; then
        echo "[*] Activating Apache binary module: php$TARGET_VERSION"
        run_cmd "a2enmod php$TARGET_VERSION" "a2enmod php$TARGET_VERSION >/dev/null 2>&1"
      else
        echo "[!] Warning: mod_php source file for PHP $TARGET_VERSION was not found."
      fi
    fi
  fi

  if [ "$MODE" = "fpm" ]; then
    echo "[+] Stripping active mod_php conflicts (Enforcing FPM environment)..."
    ls /etc/apache2/mods-enabled/php*.load 2>/dev/null | awk -F/ '{print $5}' | sed 's/.load//' | while read -r old_mod; do
      echo "[*] Disabling legacy Apache binary module: $old_mod"
      run_cmd "a2dismod $old_mod" "a2dismod $old_mod >/dev/null 2>&1"
    done
  fi

  # Process Apache Conf changes (PHP-FPM proxies)
  if [ "$MODE" = "auto" ] || [ "$MODE" = "fpm" ]; then
    echo "[+] Checking Apache FPM configurations..."
    echo "[*] Activating required Apache core modules: proxy & proxy_fcgi"
    run_cmd "a2enmod proxy proxy_fcgi" "a2enmod proxy proxy_fcgi >/dev/null 2>&1"

    CURRENT_FPM_CONF=$(ls /etc/apache2/conf-enabled/php*-fpm.conf 2>/dev/null | awk -F/ '{print $5}' | sed 's/.conf//')

    if [ ! -z "$CURRENT_FPM_CONF" ]; then
      for old_conf in $CURRENT_FPM_CONF; do
        if [ "$old_conf" != "php$TARGET_VERSION-fpm" ]; then
          echo "[*] Disabling obsolete FPM route mapping: $old_conf"
          run_cmd "a2disconf $old_conf" "a2disconf $old_conf >/dev/null 2>&1"
        fi
      done
    fi

    if [ "$MODE" = "fpm" ] || [ -f "/etc/apache2/conf-available/php$TARGET_VERSION-fpm.conf" ]; then
      if [ -f "/etc/apache2/conf-available/php$TARGET_VERSION-fpm.conf" ]; then
        echo "[*] Activating FPM configuration wrapper: php$TARGET_VERSION-fpm"
        run_cmd "a2enconf php$TARGET_VERSION-fpm" "a2enconf php$TARGET_VERSION-fpm >/dev/null 2>&1"
      fi
    fi
  fi

  if [ "$MODE" = "mod_php" ]; then
    echo "[+] Purging active FPM routing wrappers (Enforcing mod_php environment)..."
    ls /etc/apache2/conf-enabled/php*-fpm.conf 2>/dev/null | awk -F/ '{print $5}' | sed 's/.conf//' | while read -r old_conf; do
      echo "[*] Disabling obsolete FPM route mapping: $old_conf"
      run_cmd "a2disconf $old_conf" "a2disconf $old_conf >/dev/null 2>&1"
    done
  fi
fi

# === SAFETY INTERCEPT: PHP-FPM & APACHE CONFIG TEST & ROLLBACK ===
if [ "$DRY_RUN" = false ]; then
  # 1. Test PHP-FPM Configuration Syntax (Only if Apache & FPM mode is being updated)
  if [ "$TARGET_APACHE" = true ] && { [ "$MODE" = "fpm" ] || [ "$MODE" = "auto" ]; }; then
    if [ -x "/usr/sbin/php-fpm$TARGET_VERSION" ]; then
      echo "[+] Performing pre-flight PHP-FPM$TARGET_VERSION syntax validation..."
      FPM_TEST_OUTPUT=$( "/usr/sbin/php-fpm$TARGET_VERSION" -t 2>&1 )
      
      if [ $? -ne 0 ]; then
        echo ""
        echo "[-] CRITICAL CONFIGURATION FAULT DETECTED IN PHP.INI / FPM POOLS!"
        echo "    Aborting switch sequence to prevent server configuration collapse."
        echo "----------------------------------------------------------------------"
        echo "$FPM_TEST_OUTPUT"
        echo "----------------------------------------------------------------------"
        EXECUTE_ROLLBACK=true
      fi
    fi
  fi

  # 2. Test Apache Configuration Syntax (If Apache is targeted and previous test passed)
  if [ "$TARGET_APACHE" = true ] && [ "$EXECUTE_ROLLBACK" = false ]; then
    echo "[+] Performing pre-flight Apache syntax integrity validation..."
    CONFIG_TEST_OUTPUT=$(apache2ctl configtest 2>&1)
    
    if [ $? -ne 0 ]; then
      echo ""
      echo "[-] CRITICAL CONFIGURATION FAULT DETECTED IN APACHE VHOSTS!"
      echo "    Aborting switch sequence to prevent production webserver downtime."
      echo "----------------------------------------------------------------------"
      echo "$CONFIG_TEST_OUTPUT"
      echo "----------------------------------------------------------------------"
      EXECUTE_ROLLBACK=true
    fi
  fi

  # 3. Handle Rollback Execution if either test failed
  if [ "$EXECUTE_ROLLBACK" = true ]; then
    echo "[*] Commencing automated environment rolling rollback..."
    
    # Revert CLI if it was modified
    if [ "$TARGET_CLI" = true ] && [ ! -z "$PREVIOUS_VERSION" ]; then
      update-alternatives --set php "/usr/bin/php$PREVIOUS_VERSION" >/dev/null 2>&1
    fi
    
    # Revert Apache settings if they were modified
    if [ "$TARGET_APACHE" = true ]; then
      ls /etc/apache2/mods-enabled/php*.load 2>/dev/null | awk -F/ '{print $5}' | sed 's/.load//' | while read -r current_mod; do
        a2dismod "$current_mod" >/dev/null 2>&1
      done
      if [ ! -z "$PREVIOUS_MOD" ]; then
        a2enmod "$PREVIOUS_MOD" >/dev/null 2>&1
      fi
      
      ls /etc/apache2/conf-enabled/php*-fpm.conf 2>/dev/null | awk -F/ '{print $5}' | sed 's/.conf//' | while read -r current_conf; do
        a2disconf "$current_conf" >/dev/null 2>&1
      done
      if [ ! -z "$PREVIOUS_CONF" ]; then
        a2enconf "$PREVIOUS_CONF" >/dev/null 2>&1
      fi
    fi
    
    echo "[+] System rollback successfully completed. Server state preserved."
    exit 1
  else
    if [ "$TARGET_APACHE" = true ]; then
      echo "[+] All pre-flight syntax tests passed successfully! Safe to cycle services."
    fi
  fi
else
  if [ "$TARGET_APACHE" = true ]; then
    if [ "$MODE" = "fpm" ] || [ "$MODE" = "auto" ]; then
      echo -e "  \033[33m[DRY RUN]\033[0m Would execute: php-fpm$TARGET_VERSION -t"
    fi
    echo -e "  \033[33m[DRY RUN]\033[0m Would execute: apache2ctl configtest"
  fi
fi

# 4. Cycle Services and Flush Engine Memory (Only if Apache targets were modified)
if [ "$TARGET_APACHE" = true ]; then
  echo "[+] Cycling process management subsystems..."
  if [ "$DRY_RUN" = false ]; then
    for fpm_service in $(systemctl list-units --type=service --state=running --no-legend --no-pager | grep php | awk '{print $1}'); do
      echo "[*] Purging byte-code storage caches via recycle: $fpm_service"
      systemctl restart "$fpm_service" >/dev/null 2>&1
    done

    if systemctl list-unit-files --no-legend --no-pager | grep -q "php$TARGET_VERSION-fpm.service"; then
      systemctl start "php$TARGET_VERSION-fpm" >/dev/null 2>&1
    fi
    systemctl restart apache2
  else
    run_cmd "systemctl restart php-fpm services" "true"
    run_cmd "systemctl restart apache2" "true"
  fi
fi

echo "--------------------------------------------------------"
if [ "$DRY_RUN" = true ]; then
  echo -e "\033[33m[+] Dry run simulation finished cleanly. No active configurations were altered.\033[0m"
else
  echo "[+] Target environment deployed cleanly!"
fi
echo ""

# === VERIFICATION REPORT ===
echo "[+] Verification Overview:"
if [ "$DRY_RUN" = true ]; then
  echo "  [*] Active CLI instance:      (Simulated - No change)"
  echo "  [*] Loaded Apache Driver:     (Simulated - No change)"
else
  echo "  [*] Active CLI instance:      $(php -v | head -n 1 | awk '{print $2}')"

  ACTIVE_MOD=$(ls /etc/apache2/mods-enabled/php*.load 2>/dev/null | awk -F/ '{print $5}' | sed 's/.load//')
  ACTIVE_CONF=$(ls /etc/apache2/conf-enabled/php*-fpm.conf 2>/dev/null | awk -F/ '{print $5}' | sed 's/.conf//')

  if [ ! -z "$ACTIVE_MOD" ]; then
    echo "  [*] Loaded Apache Driver:     Embedded Module Mode ($ACTIVE_MOD)"
  fi
  if [ ! -z "$ACTIVE_CONF" ]; then
    echo "  [*] Loaded Apache Driver:     Isolated PHP-FPM Service ($ACTIVE_CONF)"
  fi
  if [ -z "$ACTIVE_MOD" ] && [ -z "$ACTIVE_CONF" ]; then
    echo "  [-] Loaded Apache Driver:     No driver active or server component skipped."
  fi
fi
echo ""
