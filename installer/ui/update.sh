#!/bin/bash

########################################################################
#                 Luxodactyl Installer — Update Wizard                 #
#                                                                      #
#  Lets the user stay on or switch release channels, checks whether a #
#  newer release exists on that channel, and if so confirms with the  #
#  user before handing off to installers/update.sh.                   #
########################################################################

check_root
check_os_supported

if ! panel_is_installed; then
  abort_install "No existing panel installation was found at ${INSTALL_DIR}. Use 'Install the panel' instead."
fi

if [ ! -d "${INSTALL_DIR}/.git" ]; then
  abort_install "${INSTALL_DIR} isn't a git checkout, so it can't be updated automatically (it may have been deployed from a release tarball instead). Reinstall via 'Install the panel' to switch to a git-based deployment first."
fi

CURRENT_CHANNEL="$(grep -E '^APP_UPDATE_CHANNEL=' "${INSTALL_DIR}/.env" 2>/dev/null | cut -d= -f2-)"
[ -z "$CURRENT_CHANNEL" ] && CURRENT_CHANNEL="release"

ask_channel TARGET_CHANNEL "$CURRENT_CHANNEL"

output "Checking for updates on the ${TARGET_CHANNEL} channel..."
LATEST_TAG="$(get_release_for_channel "fernsehheft/Luxodactyl" "$TARGET_CHANNEL")"

if [ -z "$LATEST_TAG" ] && [ "$TARGET_CHANNEL" != "$CURRENT_CHANNEL" ]; then
  warning "No ${TARGET_CHANNEL} release is currently available."
  echo -n "* Stay on the ${CURRENT_CHANNEL} channel instead? (Y/n): "
  read -r STAY_ON_CURRENT
  if [[ "$STAY_ON_CURRENT" =~ [Nn] ]]; then
    abort_install "Update cancelled — no ${TARGET_CHANNEL} release to switch to."
  fi
  TARGET_CHANNEL="$CURRENT_CHANNEL"
  LATEST_TAG="$(get_release_for_channel "fernsehheft/Luxodactyl" "$TARGET_CHANNEL")"
fi

if [ -z "$LATEST_TAG" ]; then
  abort_install "Could not find a ${TARGET_CHANNEL} release. Either GitHub is unreachable, or none has been published yet."
fi

CURRENT_VERSION="$(grep -E '^APP_VERSION=' "${INSTALL_DIR}/.env" 2>/dev/null | cut -d= -f2-)"
[ -z "$CURRENT_VERSION" ] && CURRENT_VERSION="unknown (development install, not pinned to a release)"

echo ""
print_brake 60
output "Current channel:      ${COLOR_CYAN}${CURRENT_CHANNEL}${COLOR_NC}"
output "Currently installed:  ${COLOR_CYAN}${CURRENT_VERSION}${COLOR_NC}"
output "Target channel:       ${COLOR_CYAN}${TARGET_CHANNEL}${COLOR_NC}"
output "Latest available:     ${COLOR_CYAN}${LATEST_TAG}${COLOR_NC}"
print_brake 60

if [ "$TARGET_CHANNEL" == "$CURRENT_CHANNEL" ] && [ "$CURRENT_VERSION" == "$LATEST_TAG" ]; then
  success "You are already running the latest ${CURRENT_CHANNEL} version (${LATEST_TAG})."
  exit 0
fi

echo ""
warning "Updating pulls the panel's code to ${LATEST_TAG}, reinstalls dependencies, rebuilds the"
warning "frontend and runs database migrations. The panel is put into maintenance mode for the"
warning "duration of the update (existing servers keep running; the web panel briefly won't)."
echo -n "* Update to ${LATEST_TAG} (${TARGET_CHANNEL} channel) now? (y/N): "
read -r CONFIRM_UPDATE
if [[ ! "$CONFIRM_UPDATE" =~ [Yy] ]]; then
  abort_install "Update cancelled."
fi

export UPDATE_TARGET_TAG="$LATEST_TAG"
export UPDATE_TARGET_CHANNEL="$TARGET_CHANNEL"
run_installer "update"
