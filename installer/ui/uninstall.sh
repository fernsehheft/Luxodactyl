#!/bin/bash

########################################################################
#                Luxodactyl Installer — Uninstall Wizard               #
########################################################################

check_root
detect_os

output "What would you like to uninstall?"
output "[0] Panel"
output "[1] Wings"
echo -n "* Input 0-1: "
read -r target

echo ""
warning "This will remove the selected component. Databases are NOT dropped automatically."
echo -n "* Are you absolutely sure? Type 'yes' to continue: "
read -r CONFIRM
[ "$CONFIRM" != "yes" ] && abort_install "Uninstall aborted."

uninstall_panel() {
  output "Stopping and removing the queue worker service..."
  systemctl disable --now luxodactyl.service 2>/dev/null || true
  rm -f /etc/systemd/system/luxodactyl.service
  systemctl daemon-reload

  output "Removing the scheduler cronjob..."
  crontab -l -u www-data 2>/dev/null | grep -v "artisan schedule:run" | crontab -u www-data - 2>/dev/null || true

  output "Removing the Nginx site..."
  rm -f /etc/nginx/sites-enabled/luxodactyl.conf /etc/nginx/sites-available/luxodactyl.conf
  systemctl restart nginx 2>/dev/null || true

  output "Removing panel files at ${INSTALL_DIR}..."
  rm -rf "$INSTALL_DIR"

  success "Panel uninstalled. The database '${MYSQL_DB:-panel}' was left intact."
}

uninstall_wings() {
  output "Stopping and removing Wings..."
  systemctl disable --now wings 2>/dev/null || true
  rm -f /etc/systemd/system/wings.service
  systemctl daemon-reload
  rm -f /usr/local/bin/wings
  success "Wings uninstalled. Docker and /etc/luxodactyl were left intact."
}

case "$target" in
  0) uninstall_panel ;;
  1) uninstall_wings ;;
  *) abort_install "Invalid option." ;;
esac
