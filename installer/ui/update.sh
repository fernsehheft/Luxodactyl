#!/bin/bash

########################################################################
#                 Luxodactyl Installer — Update Wizard                 #
#                                                                      #
#  Checks whether a newer release exists and, if so, confirms with    #
#  the user before handing off to installers/update.sh.               #
########################################################################

check_root
check_os_supported

if ! panel_is_installed; then
  abort_install "No existing panel installation was found at ${INSTALL_DIR}. Use 'Install the panel' instead."
fi

if [ ! -d "${INSTALL_DIR}/.git" ]; then
  abort_install "${INSTALL_DIR} isn't a git checkout, so it can't be updated automatically (it may have been deployed from a release tarball instead). Reinstall via 'Install the panel' to switch to a git-based deployment first."
fi

output "Checking for updates..."

LATEST_TAG="$(get_latest_release "fernsehheft/Luxodactyl")"
if [ -z "$LATEST_TAG" ]; then
  abort_install "Could not reach GitHub to check for the latest release. Check your internet connection and try again."
fi

CURRENT_VERSION="$(grep -E '^APP_VERSION=' "${INSTALL_DIR}/.env" 2>/dev/null | cut -d= -f2-)"
[ -z "$CURRENT_VERSION" ] && CURRENT_VERSION="unknown (development install, not pinned to a release)"

echo ""
print_brake 60
output "Currently installed: ${COLOR_CYAN}${CURRENT_VERSION}${COLOR_NC}"
output "Latest available:    ${COLOR_CYAN}${LATEST_TAG}${COLOR_NC}"
print_brake 60

if [ "$CURRENT_VERSION" == "$LATEST_TAG" ]; then
  success "You are already running the latest version (${LATEST_TAG})."
  exit 0
fi

echo ""
warning "Updating pulls the panel's code to ${LATEST_TAG}, reinstalls dependencies, rebuilds the"
warning "frontend and runs database migrations. The panel is put into maintenance mode for the"
warning "duration of the update (existing servers keep running; the web panel briefly won't)."
echo -n "* Update to ${LATEST_TAG} now? (y/N): "
read -r CONFIRM_UPDATE
if [[ ! "$CONFIRM_UPDATE" =~ [Yy] ]]; then
  abort_install "Update cancelled."
fi

export UPDATE_TARGET_TAG="$LATEST_TAG"
run_installer "update"
