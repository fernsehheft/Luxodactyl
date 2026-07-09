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
#                     Animated progress (spinner)                        #
# --------------------------------------------------------------------- #
# spin "<label>" <command> [args...]
#   Runs the command with ALL of its output redirected to the log file,
#   while showing an animated spinner on the terminal (fd 3, which
#   bypasses the tee so frames never land in the log). Prints a green
#   check on success or a red cross + non-zero return on failure.
#   Falls back to a plain status line when no terminal is available.
spin() {
  local label="$1"
  shift
  local rc=0

  # No animation possible (piped/non-tty): run plainly.
  if [ "${LUX_ANIMATE:-0}" != "1" ]; then
    output "$label ..."
    ( "$@" >>"$LOG_PATH" 2>&1 ) || rc=$?
    if [ "$rc" -eq 0 ]; then
      output "  ${COLOR_GREEN}[done]${COLOR_NC} $label"
    else
      output "  ${COLOR_RED}[failed]${COLOR_NC} $label (see $LOG_PATH)"
      return "$rc"
    fi
    return 0
  fi

  ( "$@" >>"$LOG_PATH" 2>&1 ) &
  local pid=$!
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local n=${#frames[@]} i=0

  printf '\033[?25l' >&3 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  \033[36m%s\033[0m %s ' "${frames[i % n]}" "$label" >&3 2>/dev/null || true
    sleep 0.1
    i=$((i + 1))
  done
  wait "$pid" || rc=$?
  printf '\033[?25h' >&3 2>/dev/null || true

  if [ "$rc" -eq 0 ]; then
    printf '\r  \033[32m✔\033[0m %s\033[K\n' "$label" >&3 2>/dev/null || true
    echo "[OK] $label" >>"$LOG_PATH"
    return 0
  fi

  # --- failure path ---------------------------------------------------- #
  printf '\r  \033[31m✘\033[0m %s\033[K\n' "$label" >&3 2>/dev/null || true
  echo "[FAILED] $label (rc=$rc)" >>"$LOG_PATH"

  # The step's output was redirected to the log, so surface the tail right
  # here — the user (or an AI) gets the actual error without digging.
  {
    echo ""
    echo -e "  \033[31mThis step failed.\033[0m Last lines of the log:"
    echo "  ------------------------------------------------------------------"
    tail -n 25 "$LOG_PATH" 2>/dev/null | sed 's/^/  | /'
    echo "  ------------------------------------------------------------------"
    echo -e "  Full log: \033[36m${LOG_PATH}\033[0m  (send it to support or an AI)"
    echo ""
  } >&3 2>/dev/null || true

  # Clear the error trap and errexit before exiting so the shell unwinds
  # cleanly (prevents the bash 'pop_var_context' warning) and doesn't
  # re-enter installer_failed.
  set +e
  trap - ERR
  exit "$rc"
}
export -f spin

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
      if [ "$kind" == "panel" ]; then
        abort_install "${kind} is already installed. Nothing to do. (Looking to upgrade instead? Choose 'Update the panel' from the main menu.)"
      else
        abort_install "${kind} is already installed. Nothing to do."
      fi
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
#                        DNS / A-record checking                         #
# --------------------------------------------------------------------- #
# Best-effort public IPv4 of this machine.
get_server_ip() {
  local ip=""
  ip="$(curl -fsSL --max-time 8 https://api.ipify.org 2>/dev/null)" || ip=""
  [ -z "$ip" ] && ip="$(curl -fsSL --max-time 8 https://ifconfig.me 2>/dev/null)" || true
  [ -z "$ip" ] && ip="$(curl -fsSL --max-time 8 https://ipv4.icanhazip.com 2>/dev/null | tr -d '[:space:]')" || true
  [ -z "$ip" ] && ip="$(hostname -I 2>/dev/null | awk '{print $1}')" || true
  echo "$ip"
}

# Resolve the first IPv4 an FQDN currently points to (empty if unresolved).
get_dns_ip() {
  getent ahostsv4 "$1" 2>/dev/null | awk '{print $1; exit}'
}

# True if the IPv4 belongs to a Cloudflare range (proxied / orange cloud).
# Covers Cloudflare's published ranges; used for messaging only.
is_cloudflare_ip() {
  case "$1" in
    104.1[6-9].* | 104.2[0-9].* | 104.3[01].*) return 0 ;;            # 104.16.0.0/13
    172.6[4-9].* | 172.7[01].*) return 0 ;;                           # 172.64.0.0/13
    162.158.* | 162.159.*) return 0 ;;                                # 162.158.0.0/15
    173.245.4[89].* | 173.245.5[0-9].* | 173.245.6[0-3].*) return 0 ;;# 173.245.48.0/20
    108.162.*) return 0 ;;                                            # 108.162.192.0/18
    141.101.6[4-9].* | 141.101.[7-9][0-9].* | 141.101.1[01][0-9].* | 141.101.12[0-7].*) return 0 ;; # 141.101.64.0/18
    190.93.24[0-9].* | 190.93.25[0-5].*) return 0 ;;                  # 190.93.240.0/20
    188.114.9[6-9].* | 188.114.1[01][0-9].*) return 0 ;;              # 188.114.96.0/20
    197.234.24[0-3].*) return 0 ;;                                    # 197.234.240.0/22
    198.41.12[89].* | 198.41.1[3-9][0-9].* | 198.41.2[0-5][0-9].*) return 0 ;; # 198.41.128.0/17
    103.21.244.* | 103.21.245.* | 103.22.20[0-3].* | 103.31.[4-7].*) return 0 ;;
    131.0.7[2-5].*) return 0 ;;                                       # 131.0.72.0/22
    *) return 1 ;;
  esac
}

# wait_for_dns <fqdn>
#   Shows the required A-record, then loops until the FQDN resolves to this
#   server. The user can recheck, skip the check, or abort at any time.
wait_for_dns() {
  local fqdn="$1"
  local server_ip
  server_ip="$(get_server_ip)"

  echo ""
  print_brake 60
  output "DNS check for ${COLOR_CYAN}${fqdn}${COLOR_NC}"
  print_brake 60
  output "Before a certificate can be issued, this domain must point to THIS server."
  output "Create the following DNS record at your domain provider:"
  echo ""
  output "    Type:  ${COLOR_CYAN}A${COLOR_NC}"
  output "    Name:  ${COLOR_CYAN}${fqdn}${COLOR_NC}"
  output "    Value: ${COLOR_CYAN}${server_ip:-<your server IP>}${COLOR_NC}"
  echo ""

  while true; do
    local resolved
    resolved="$(get_dns_ip "$fqdn")"

    if [ -n "$server_ip" ] && [ "$resolved" == "$server_ip" ]; then
      success "${fqdn} correctly resolves to ${server_ip}."
      return 0
    fi

    # Cloudflare (or another proxy) in front of the record: the resolved IP is
    # the proxy's, not this server's. The record IS set, so don't block on it.
    if [ -n "$resolved" ] && is_cloudflare_ip "$resolved"; then
      success "${fqdn} resolves to ${resolved} — a Cloudflare IP (proxy is enabled). The DNS record is set."
      output "For a local Let's Encrypt certificate you would need 'DNS only' (grey cloud); otherwise use Cloudflare's own SSL."
      return 0
    fi

    if [ -n "$resolved" ]; then
      warning "${fqdn} currently resolves to '${resolved}', expected '${server_ip}'. DNS may still be propagating."
    else
      warning "${fqdn} does not resolve yet (record missing or still propagating)."
    fi

    echo -n "* [Enter] recheck   [s] skip check & continue   [a] abort : "
    if ! read -r DNS_ANS; then
      # No interactive input available (EOF) — don't spin forever.
      warning "No input available — skipping DNS verification."
      return 0
    fi
    case "$DNS_ANS" in
      s | S) warning "Skipping DNS verification — continuing without it."; return 0 ;;
      a | A) abort_install "Aborted before SSL setup." ;;
      *) : ;; # loop and recheck
    esac
  done
}

export -f get_server_ip get_dns_ip wait_for_dns

# --------------------------------------------------------------------- #
#                      Release / version helpers                         #
# --------------------------------------------------------------------- #
get_latest_release() {
  # $1 = owner/repo
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

# set_env_value <key> <value> <env-file>
#   Replaces KEY=... in the given .env file, or appends it if the key isn't
#   present yet (e.g. upgrading an install from before that key existed).
set_env_value() {
  local key="$1" value="$2" file="$3"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s#^${key}=.*#${key}=${value}#" "$file"
  else
    echo "${key}=${value}" >>"$file"
  fi
}

export -f get_latest_release set_env_value

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

  # Small helper: print a line, then pause briefly for a reveal effect
  # (only when we have a real terminal, so piped output stays instant).
  local d="0.045"
  [ "${LUX_ANIMATE:-0}" = "1" ] || d="0"

  echo -e "${COLOR_CYAN}${COLOR_BOLD}"
  local lines=(
    "######################################################################"
    "#                                                                    #"
    "#                     Luxodactyl Installer                           #"
    "#                                                                    #"
    "#   Modern game server management panel — forked from Pterodactyl    #"
    "#                                                                    #"
    "######################################################################"
  )
  local line
  for line in "${lines[@]}"; do
    echo "$line"
    [ "$d" != "0" ] && sleep "$d"
  done
  echo -e "${COLOR_NC}"

  # A short cyan "loading" sweep under the banner.
  if [ "${LUX_ANIMATE:-0}" = "1" ]; then
    local bar=""
    printf '  '
    for _ in $(seq 1 24); do
      bar="${bar}━"
      printf '\r  \033[36m%s\033[0m' "$bar"
      sleep 0.02
    done
    printf '\n\n'
  fi

  output "Copyright (C) 2026 — present, Luxodactyl contributors."
  output "This installer is not officially associated with Pterodactyl."
  echo ""
}

export -f welcome
