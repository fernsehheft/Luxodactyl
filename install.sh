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

LOG_PATH="/var/log/luxodactyl-installer.log"
export LOG_PATH

# --------------------------------------------------------------------- #
# Pre-flight: this bootstrap only needs curl. Everything else is checked
# once the shared library has been loaded.
# --------------------------------------------------------------------- #
if ! command -v curl >/dev/null 2>&1; then
  echo "* curl is required to run this installer."
  echo "* Install it first, e.g.  apt-get update && apt-get install -y curl"
  exit 1
fi

# --------------------------------------------------------------------- #
# Determine whether we are running from a local checkout of the repo.
# If the installer files exist next to this script we source them
# locally (useful for development); otherwise we download them from
# GitHub so that `curl | bash` works.
# --------------------------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/installer/lib/lib.sh" ]; then
  export INSTALLER_DIR="$SCRIPT_DIR/installer"
else
  export INSTALLER_DIR=""
fi

# fetch_source <relative-path-under-installer/>
#   Prints the requested file to stdout, from disk if available,
#   otherwise from GitHub.
fetch_source() {
  local rel="$1"
  if [ -n "$INSTALLER_DIR" ] && [ -f "$INSTALLER_DIR/$rel" ]; then
    cat "$INSTALLER_DIR/$rel"
  else
    curl -fsSL "$GITHUB_URL/$rel" || {
      echo "* Failed to download $rel from $GITHUB_URL/$rel" 1>&2
      exit 1
    }
  fi
}
export -f fetch_source

# Load the shared library.
# shellcheck source=/dev/null
source <(fetch_source "lib/lib.sh")

# --------------------------------------------------------------------- #
# execute <installer> [after-message]
#   Runs a UI wizard followed by its installer, then optionally offers
#   to continue with a second installer.
# --------------------------------------------------------------------- #
execute() {
  local install_type="$1"
  local next="$2"

  echo -e "\n\n* luxodactyl-installer $(date) \n\n" >>"$LOG_PATH"

  run_ui "${install_type}" |& tee -a "$LOG_PATH"

  if [ -n "$next" ]; then
    echo -e -n "* Installation of ${install_type} completed. Do you want to proceed to ${next} installation? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Yy] ]]; then
      execute "$next"
    else
      error "Installation of ${next} aborted."
      exit 1
    fi
  fi
}

welcome ""

done=false
while [ "$done" == false ]; do
  options=(
    "Install the panel"
    "Install Wings"
    "Install both [0] and [1] on the same machine (wings script runs after panel)"
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
