#!/bin/bash

########################################################################
#              Luxodactyl Installer — Let's Encrypt (SSL)              #
########################################################################

check_root
check_os_supported

output "This wizard requests a free Let's Encrypt SSL certificate for a domain."
output "Nginx must already serve that domain on port 80 and it must resolve to this server."
echo ""

required_input FQDN "Domain to secure (panel.example.com): " "A domain is required."
email_input LE_EMAIL "Email for certificate registration: " "Please enter a valid email."

install_packages "certbot python3-certbot-nginx"

if certbot --nginx -d "$FQDN" --non-interactive --agree-tos -m "$LE_EMAIL" --redirect; then
  success "SSL certificate installed for ${FQDN}."
else
  error "Failed to obtain the SSL certificate. Check the log at ${LOG_PATH}."
  exit 1
fi
