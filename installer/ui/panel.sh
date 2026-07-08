#!/bin/bash

########################################################################
#                  Luxodactyl Installer — Panel Wizard                 #
#                                                                      #
#  Collects all configuration from the user, prints a summary, asks   #
#  for confirmation and then hands off to installers/panel.sh.        #
########################################################################

check_root
check_os_supported
check_virt

output "Starting the Luxodactyl panel installation wizard."
output "You will be asked a few questions. Press Enter to accept the [default] where offered."
echo ""

# --------------------------------------------------------------------- #
#                              Database                                 #
# --------------------------------------------------------------------- #
print_brake 40
output "Database configuration"
print_brake 40
output "A dedicated MySQL/MariaDB database and user will be created for the panel."
echo ""

required_input MYSQL_DB "Database name [panel]: " "" "panel"
required_input MYSQL_USER "Database username [luxodactyl]: " "" "luxodactyl"

MYSQL_PASSWORD=""
echo -n "* Database password (leave empty to auto-generate a strong one): "
read -r -s MYSQL_PASSWORD
echo ""
if [ -z "$MYSQL_PASSWORD" ]; then
  MYSQL_PASSWORD=$(gen_passwd 24)
  output "A random database password has been generated."
fi

# --------------------------------------------------------------------- #
#                            Panel domain                              #
# --------------------------------------------------------------------- #
echo ""
print_brake 40
output "Panel domain / URL"
print_brake 40
output "Enter the FQDN this panel will be reached at (e.g. panel.example.com)."
output "It must already point (A/AAAA record) to this server's IP."
echo ""

required_input FQDN "FQDN (panel.example.com): " "FQDN is required."

# --------------------------------------------------------------------- #
#                              Timezone                                #
# --------------------------------------------------------------------- #
echo ""
required_input TIMEZONE "Timezone [Europe/Berlin]: " "" "Europe/Berlin"

# --------------------------------------------------------------------- #
#                         Administrator account                        #
# --------------------------------------------------------------------- #
echo ""
print_brake 40
output "Administrator account"
print_brake 40

email_input ADMIN_EMAIL "Email for Let's Encrypt & panel author (admin@example.com): " "Please enter a valid email."
USER_EMAIL="$ADMIN_EMAIL"

required_input USER_USERNAME "Admin username [admin]: " "" "admin"
required_input USER_FIRSTNAME "Admin first name [Admin]: " "" "Admin"
required_input USER_LASTNAME "Admin last name [User]: " "" "User"
password_input USER_PASSWORD "Admin password: " "Password cannot be empty."

# --------------------------------------------------------------------- #
#                                 SSL                                  #
# --------------------------------------------------------------------- #
echo ""
print_brake 40
output "SSL configuration"
print_brake 40

ASSUME_SSL=false
CONFIGURE_LETSENCRYPT=false

echo -n "* Automatically obtain a free Let's Encrypt SSL certificate? (y/N): "
read -r CONFIRM_SSL
if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
  CONFIGURE_LETSENCRYPT=true
  ASSUME_SSL=true
else
  echo -n "* Do you already have SSL certs and want the HTTPS nginx config anyway? (y/N): "
  read -r CONFIRM_ASSUME
  [[ "$CONFIRM_ASSUME" =~ [Yy] ]] && ASSUME_SSL=true
fi

# --------------------------------------------------------------------- #
#                               Firewall                               #
# --------------------------------------------------------------------- #
echo ""
ask_firewall CONFIGURE_FIREWALL

# --------------------------------------------------------------------- #
#                               Summary                                #
# --------------------------------------------------------------------- #
echo ""
print_brake 70
output "Installation summary"
print_brake 70
output "Database name:        ${COLOR_CYAN}${MYSQL_DB}${COLOR_NC}"
output "Database user:        ${COLOR_CYAN}${MYSQL_USER}${COLOR_NC}"
output "Database password:    ${COLOR_CYAN}${MYSQL_PASSWORD}${COLOR_NC}"
output "Panel FQDN:           ${COLOR_CYAN}${FQDN}${COLOR_NC}"
output "Timezone:             ${COLOR_CYAN}${TIMEZONE}${COLOR_NC}"
output "Admin email:          ${COLOR_CYAN}${ADMIN_EMAIL}${COLOR_NC}"
output "Admin username:       ${COLOR_CYAN}${USER_USERNAME}${COLOR_NC}"
output "Configure SSL:        ${COLOR_CYAN}${CONFIGURE_LETSENCRYPT}${COLOR_NC}"
output "Configure firewall:   ${COLOR_CYAN}${CONFIGURE_FIREWALL}${COLOR_NC}"
print_brake 70
warning "Write down the database password above — it will be needed for recovery."
echo ""

echo -n "* Proceed with the installation? (y/N): "
read -r CONFIRM_INSTALL
if [[ ! "$CONFIRM_INSTALL" =~ [Yy] ]]; then
  error "Installation aborted by user."
  exit 1
fi

export MYSQL_DB MYSQL_USER MYSQL_PASSWORD FQDN TIMEZONE
export ADMIN_EMAIL USER_EMAIL USER_USERNAME USER_FIRSTNAME USER_LASTNAME USER_PASSWORD
export ASSUME_SSL CONFIGURE_LETSENCRYPT CONFIGURE_FIREWALL

run_installer "panel"
