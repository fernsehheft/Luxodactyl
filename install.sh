#!/bin/bash

set -e

########################################################################
#                                                                      #
#                    Luxodactyl Installer Bootstrap                    #
#                                                                      #
#  Modular installer inspired by pterodactyl-installer.                #
#  Run with:                                                           #
#                                                                      #
#    bash <(curl -sSL https://raw.githubusercontent.com/\             #
#      fernsehheft/Luxodactyl/main/install.sh)                         #
#                                                                      #
########################################################################

export GITHUB_SOURCE="main"
export SCRIPT_RELEASE="main"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/fernsehheft/Luxodactyl"
export GITHUB_URL="$GITHUB_BASE_URL/$GITHUB_SOURCE/installer"

# Never let corepack/pnpm block on an interactive download confirmation.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------------------------- #
# Pre-flight: this bootstrap only needs curl.
# --------------------------------------------------------------------- #
if ! command -v curl >/dev/null 2>&1; then
  echo "* curl is required to run this installer."
  echo "* Install it first, e.g.  apt-get update && apt-get install -y curl"
  exit 1
fi

# --------------------------------------------------------------------- #
# Logging: everything printed by the installer is mirrored to a log
# file so it can be shared for debugging when something crashes.
# We pick the first writable location.
# --------------------------------------------------------------------- #
LOG_PATH="/var/log/luxodactyl-installer.log"
if ! (touch "$LOG_PATH" >/dev/null 2>&1); then
  LOG_PATH="$(pwd)/luxodactyl-installer.log"
  (touch "$LOG_PATH" >/dev/null 2>&1) || LOG_PATH="/tmp/luxodactyl-installer.log"
fi
export LOG_PATH

# Mirror all stdout/stderr to the log (append) while keeping it on screen.
exec > >(tee -a "$LOG_PATH") 2>&1

# Open a direct handle to the terminal (fd 3) for animations, bypassing the
# tee so spinner frames never end up in the log. Disable animation if there
# is no usable terminal (e.g. output is being piped somewhere).
if ( : >/dev/tty ) 2>/dev/null; then
  exec 3>/dev/tty
  export LUX_ANIMATE=1
else
  exec 3>&1
  export LUX_ANIMATE=0
fi

{
  echo ""
  echo "==================================================================="
  echo "Luxodactyl installer — new run at $(date)"
  echo "Log file: $LOG_PATH"
  echo "==================================================================="
} >>"$LOG_PATH"

# --------------------------------------------------------------------- #
# Friendly failure handler. Fires on any unhandled command failure
# (set -e) and tells the user exactly where to find the log.
# --------------------------------------------------------------------- #
installer_failed() {
  local code=$?
  # Exit code 3 is a controlled abort (user cancelled, unmet precondition).
  # Those already printed their own message, so don't add the crash notice.
  if [ "$code" -eq 3 ]; then
    exit 3
  fi
  echo ""
  echo -e "* \033[0;31mERROR\033[0m: The installation stopped unexpectedly (exit code ${code})."
  echo "* A full log of this run was saved to:"
  echo "*     ${LOG_PATH}"
  echo "*"
  echo "* You can send that file to support or paste it into an AI assistant"
  echo "* to diagnose the problem. NOTE: it may contain the generated database"
  echo "* password — remove that line before sharing publicly."
  echo ""
  exit "$code"
}
trap installer_failed ERR

# --------------------------------------------------------------------- #
# Determine whether we are running from a local checkout of the repo.
# --------------------------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/installer/lib/lib.sh" ]; then
  export INSTALLER_DIR="$SCRIPT_DIR/installer"
else
  export INSTALLER_DIR=""
fi

# Temp dir the module files are materialised into, so we source real
# files (not process substitution) — this keeps `set -e` / exit codes
# reliable and avoids bash "pop_var_context" noise on failure.
LUXO_TMP="$(mktemp -d 2>/dev/null || echo /tmp/luxodactyl-installer.$$)"
mkdir -p "$LUXO_TMP"
export LUXO_TMP
cleanup_tmp() { rm -rf "$LUXO_TMP" 2>/dev/null || true; }
trap cleanup_tmp EXIT

# fetch_source <relative-path-under-installer/>
#   Materialises the requested file into $LUXO_TMP and prints its path.
#   Sources it from disk if available, otherwise downloads from GitHub.
fetch_source() {
  local rel="$1"
  local dest="$LUXO_TMP/${rel//\//__}"
  if [ -n "$INSTALLER_DIR" ] && [ -f "$INSTALLER_DIR/$rel" ]; then
    cp "$INSTALLER_DIR/$rel" "$dest"
  else
    if ! curl -fsSL "$GITHUB_URL/$rel" -o "$dest"; then
      echo "* Failed to download $rel from $GITHUB_URL/$rel" 1>&2
      return 1
    fi
  fi
  echo "$dest"
}
export -f fetch_source

# Load the shared library.
LIB_FILE="$(fetch_source "lib/lib.sh")" || {
  echo "* Could not load the installer library. Check your internet connection."
  exit 1
}
# shellcheck source=/dev/null
source "$LIB_FILE"

# --------------------------------------------------------------------- #
# execute <installer> [next-installer]
# --------------------------------------------------------------------- #
execute() {
  local install_type="$1"
  local next="$2"

  run_ui "${install_type}"

  if [ -n "$next" ]; then
    echo ""
    echo -n "* Installation of ${install_type} completed. Continue with ${next}? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Yy] ]]; then
      execute "$next"
    else
      warning "Skipping ${next} installation."
    fi
  fi
}

welcome ""

done=false
while [ "$done" == false ]; do
  options=(
    "Install the panel"
    "Install Wings"
    "Install both the panel and Wings on this machine"
    "Configure Let's Encrypt SSL only"
    "Uninstall panel or wings"
  )

  actions=(
    "panel"
    "wings"
    "panel;wings"
    "ssl"
    "uninstall"
  )

  output "What would you like to do?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Input 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "Input is required" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Invalid option"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done
