#!/bin/bash

########################################################################
#                  Luxodactyl Installer — Wings Wizard                 #
########################################################################

check_root
check_os_supported

# Detect an existing Wings install and offer a complete reinstall (or abort).
detect_existing "wings"

output "Starting the Wings installation wizard."
output "Wings is the server-side daemon that runs your game servers via Docker."
echo ""

warning "Wings must run on a machine with a real (non-virtualised) kernel that supports Docker."
warning "OpenVZ / LXC containers usually do NOT work."
echo ""

# Optional: this node usually needs its own domain (FQDN) with an A-record
# pointing here, so the panel can reach it over SSL. Offer a DNS check.
echo -n "* Node domain/FQDN to verify its DNS A-record (leave empty to skip): "
read -r WINGS_FQDN
if [ -n "$WINGS_FQDN" ]; then
  wait_for_dns "$WINGS_FQDN"
fi

echo ""
ask_firewall CONFIGURE_FIREWALL

echo ""
echo -n "* Proceed with the Wings installation? (y/N): "
read -r CONFIRM_INSTALL
if [[ ! "$CONFIRM_INSTALL" =~ [Yy] ]]; then
  abort_install "Installation aborted by user."
fi

export CONFIGURE_FIREWALL
run_installer "wings"
