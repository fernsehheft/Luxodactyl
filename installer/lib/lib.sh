#!/bin/bash

########################################################################
#                  Luxodactyl Installer — Shared Library               #
#                                                                      #
#  Sourced by install.sh and by the individual installer/ui scripts.  #
#  Contains colours, logging, OS detection, input helpers, database   #
#  helpers, firewall helpers and the download/run orchestration.      #
########################################################################

# Prevent double-sourcing.
if [ -n "${LUXO_LIB_LOADED:-}" ]; then return 0 2>/dev/null || true; fi
export LUXO_LIB_LOADED=1

# --------------------------------------------------------------------- #
#                             Configuration                             #
# --------------------------------------------------------------------- #

# Repository the panel is cloned from.
export LUXO_REPO="${LUXO_REPO:-https://github.com/fernsehheft/Luxodactyl.git}"
export LUXO_BRANCH="${LUXO_BRANCH:-main}"

# Where the panel gets installed.
export INSTALL_DIR="/var/www/luxodactyl"

# PHP version used by the panel.
export PHP_VERSION="8.4"

# Wings.
export WINGS_DL_BASE_URL="https://github.com/pterodactyl/wings/releases"

# Supported operating systems (name:version).
export SUPPORTED_OS="ubuntu-22 ubuntu-24 debian-11 debian-12"

# --------------------------------------------------------------------- #
#                                Colours                                 #
# --------------------------------------------------------------------- #
COLOR_NC='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_MAGENTA='\033[0;35m'
COLOR_BOLD='\033[1m'
export COLOR_NC COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_CYAN COLOR_MAGENTA COLOR_BOLD

# --------------------------------------------------------------------- #
#                            Logging helpers                             #
# --------------------------------------------------------------------- #
output() {
  echo -e "* $1"
}

success() {
  echo ""
  output "${COLOR_GREEN}SUCCESS${COLOR_NC}: $1"
  echo ""
}

error() {
  echo ""
  echo -e "* ${COLOR_RED}ERROR${COLOR_NC}: $1" 1>&2
  echo ""
}

warning() {
  echo ""
  output "${COLOR_YELLOW}WARNING${COLOR_NC}: $1"
  echo ""
}

print_brake() {
  for ((n = 0; n < $1; n++)); do
    echo -n "#"
  done
  echo ""
}

# Controlled, non-crash exit (user aborts, failed preconditions).
# Exit code 3 is recognised by the bootstrap's failure handler and does
# NOT print the "installer crashed, send the log" message.
abort_install() {
  warning "${1:-Installation aborted.}"
  exit 3
}

hyperlink() {
  echo -e "\e]8;;${1}\a${1}\e]8;;\a"
}

export -f output success error warning print_brake hyperlink abort_install

# --------------------------------------------------------------------- #
#                        Regular expressions                             #
# --------------------------------------------------------------------- #
email_regex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"

valid_email() {
  [[ $1 =~ ${email_regex} ]]
}

invalid_ip() {
  ip route get "$1" >/dev/null 2>&1
  echo $?
}

gen_passwd() {
  local length="$1"
  local password=""
  while [ "${#password}" -lt "$length" ]; do
    password=$(echo "$password$(head -c 100 /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9')" | head -c "$length")
  done
  echo "$password"
}

export -f valid_email invalid_ip gen_passwd

# --------------------------------------------------------------------- #
#                           Input helpers                                #
# --------------------------------------------------------------------- #

# required_input <var-name> <prompt> <error-msg> [default]
required_input() {
  local __resultvar="$1"
  local result=""

  while [ -z "$result" ]; do
    echo -n "* ${2}"
    read -r result

    if [ -z "${4:-}" ] && [ -z "$result" ]; then
      error "${3}"
      result=""
    else
      [ -z "$result" ] && result="${4}"
    fi
  done

  printf -v "$__resultvar" '%s' "$result"
}

# email_input <var-name> <prompt> <error-msg>
email_input() {
  local __resultvar="$1"
  local result=""

  while ! valid_email "$result"; do
    echo -n "* ${2}"
    read -r result

    valid_email "$result" || error "${3}"
  done

  printf -v "$__resultvar" '%s' "$result"
}

# password_input <var-name> <prompt> <error-msg> [default]
password_input() {
  local __resultvar="$1"
  local result=""
  local default="${4:-}"

  while [ -z "$result" ]; do
    echo -n "* ${2}"

    # Read silently, echoing an asterisk per character.
    while IFS= read -r -s -n1 char; do
      [[ -z "$char" ]] && { printf '\n'; break; }
      if [[ "$char" == $'\x7f' ]]; then
        if [ -n "$result" ]; then
          result="${result%?}"
          printf '\b \b'
        fi
      else
        result+="$char"
        printf '*'
      fi
    done

    [ -n "$default" ] && [ -z "$result" ] && result="$default"
    [ -z "$result" ] && error "${3}"
  done

  printf -v "$__resultvar" '%s' "$result"
}

export -f required_input email_input password_input

# --------------------------------------------------------------------- #
#                             OS detection                               #
# --------------------------------------------------------------------- #
detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  else
    error "Could not detect the operating system."
    exit 1
  fi

  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *) error "Unsupported CPU architecture: $ARCH"; exit 1 ;;
  esac

  export OS OS_VER OS_VER_MAJOR ARCH
}

check_os_supported() {
  detect_os

  local supported=false
  for entry in $SUPPORTED_OS; do
    if [ "${OS}-${OS_VER_MAJOR}" == "$entry" ]; then
      supported=true
      break
    fi
  done

  if [ "$supported" == false ]; then
    error "Your OS (${OS} ${OS_VER}) is not supported by this installer."
    output "Supported systems: Ubuntu 22.04 / 24.04, Debian 11 / 12."
    exit 3
  fi

  output "Detected operating system: ${COLOR_MAGENTA}${OS} ${OS_VER} (${ARCH})${COLOR_NC}"
}

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use: sudo -i)."
    exit 3
  fi
}

check_virt() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    local virt
    virt=$(systemd-detect-virt 2>/dev/null || true)
    if [ "$virt" == "openvz" ] || [ "$virt" == "lxc" ]; then
      warning "Virtualization type '$virt' detected — Wings/Docker may not work reliably here."
    fi
  fi
}

export -f detect_os check_os_supported check_root check_virt

# --------------------------------------------------------------------- #
#                    Existing-installation detection                     #
# --------------------------------------------------------------------- #
panel_is_installed() {
  [ -f "$INSTALL_DIR/.env" ] || [ -f "$INSTALL_DIR/artisan" ] || [ -f /etc/systemd/system/luxodactyl.service ]
}

wings_is_installed() {
  [ -f /usr/local/bin/wings ] || [ -f /etc/systemd/system/wings.service ]
}

# detect_existing <panel|wings>
#   If the component is already installed, warns the user and asks whether
#   to completely reinstall. Sets REINSTALL=true on confirmation, otherwise
#   aborts cleanly. Does nothing (REINSTALL=false) on a fresh machine.
detect_existing() {
  local kind="$1"
  REINSTALL=false

  local installed=1
  case "$kind" in
    panel) panel_is_installed && installed=0 ;;
    wings) wings_is_installed && installed=0 ;;
  esac

  if [ "$installed" -eq 0 ]; then
    warning "An existing ${kind} installation was detected on this machine."
    echo -n "* It looks like ${kind} is already installed. Reinstall it completely? (y/N): "
    read -r CONFIRM_REINSTALL
    if [[ "$CONFIRM_REINSTALL" =~ [Yy] ]]; then
      REINSTALL=true
      warning "Reinstall mode enabled — existing ${kind} files/services will be replaced."
    else
      abort_install "${kind} is already installed. Nothing to do."
    fi
  fi

  export REINSTALL
}

export -f panel_is_installed wings_is_installed detect_existing

# --------------------------------------------------------------------- #
#                        Package management                              #
# --------------------------------------------------------------------- #
update_repos() {
  output "Updating package repositories..."
  apt-get -y update
}

install_packages() {
  # $1 = space separated list of packages
  output "Installing packages: $1"
  # shellcheck disable=SC2086
  DEBIAN_FRONTEND=noninteractive apt-get -y install $1
}

export -f update_repos install_packages

# --------------------------------------------------------------------- #
#                          Database helpers                              #
# --------------------------------------------------------------------- #
create_db_user() {
  local user="$1"
  local password="$2"
  local host="${3:-127.0.0.1}"

  output "Creating database user '${user}'..."
  mysql -u root -e "CREATE USER IF NOT EXISTS '${user}'@'${host}' IDENTIFIED BY '${password}';"
  mysql -u root -e "FLUSH PRIVILEGES;"
}

create_db() {
  local db="$1"
  local user="$2"
  local host="${3:-127.0.0.1}"

  output "Creating database '${db}'..."
  mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${db};"
  mysql -u root -e "GRANT ALL PRIVILEGES ON ${db}.* TO '${user}'@'${host}' WITH GRANT OPTION;"
  mysql -u root -e "FLUSH PRIVILEGES;"
}

export -f create_db_user create_db

# --------------------------------------------------------------------- #
#                          Firewall helpers                              #
# --------------------------------------------------------------------- #
ask_firewall() {
  local __resultvar="$1"
  local answer="false"

  echo -n "* Do you want to automatically configure UFW (firewall)? (y/N): "
  read -r CONFIRM
  [[ "$CONFIRM" =~ [Yy] ]] && answer="true"

  printf -v "$__resultvar" '%s' "$answer"
}

install_firewall() {
  output "Installing UFW (Uncomplicated Firewall)..."
  install_packages "ufw"
  ufw --force enable
}

firewall_allow_ports() {
  for port in $1; do
    output "Allowing port ${port} through the firewall..."
    ufw allow "$port" >/dev/null
  done
  ufw --force reload
}

export -f ask_firewall install_firewall firewall_allow_ports

# --------------------------------------------------------------------- #
#                      Release / version helpers                         #
# --------------------------------------------------------------------- #
get_latest_release() {
  # $1 = owner/repo
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

export -f get_latest_release

# --------------------------------------------------------------------- #
#                    Download / run orchestration                        #
# --------------------------------------------------------------------- #
#
# run_ui and run_installer reuse fetch_source (exported by install.sh)
# so that they work whether the installer runs from a local checkout or
# straight off GitHub via curl | bash.
# --------------------------------------------------------------------- #
run_ui() {
  local name="$1"
  local file
  file="$(fetch_source "ui/${name}.sh")" || { error "Could not load UI module '${name}'."; return 1; }
  # shellcheck source=/dev/null
  source "$file"
}

run_installer() {
  local name="$1"
  local file
  file="$(fetch_source "installers/${name}.sh")" || { error "Could not load installer module '${name}'."; return 1; }
  # shellcheck source=/dev/null
  source "$file"
}

export -f run_ui run_installer

# --------------------------------------------------------------------- #
#                               Welcome                                  #
# --------------------------------------------------------------------- #
welcome() {
  clear
  echo -e "${COLOR_CYAN}${COLOR_BOLD}"
  print_brake 70
  echo "#                                                                    #"
  echo "#                     Luxodactyl Installer                           #"
  echo "#                                                                    #"
  echo "#   Modern game server management panel — forked from Pterodactyl    #"
  echo "#                                                                    #"
  print_brake 70
  echo -e "${COLOR_NC}"
  output "Copyright (C) 2026 — present, Luxodactyl contributors."
  output "This installer is not officially associated with Pterodactyl."
  echo ""
}

export -f welcome
