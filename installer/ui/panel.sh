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
output "This is the first admin user you will log in with."

email_input USER_EMAIL "Admin email (used to log in): " "Please enter a valid email."
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
LE_EMAIL=""

echo -n "* Automatically obtain a free Let's Encrypt SSL certificate? (y/N): "
read -r CONFIRM_SSL
if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
  CONFIGURE_LETSENCRYPT=true
  ASSUME_SSL=true
  # The Let's Encrypt email is only needed when SSL is requested.
  email_input LE_EMAIL "Email for Let's Encrypt (renewal notices): " "Please enter a valid email."
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
output "Admin email:          ${COLOR_CYAN}${USER_EMAIL}${COLOR_NC}"
output "Admin username:       ${COLOR_CYAN}${USER_USERNAME}${COLOR_NC}"
output "Configure SSL:        ${COLOR_CYAN}${CONFIGURE_LETSENCRYPT}${COLOR_NC}"
[ "$CONFIGURE_LETSENCRYPT" == true ] && output "Let's Encrypt email:  ${COLOR_CYAN}${LE_EMAIL}${COLOR_NC}"
output "Configure firewall:   ${COLOR_CYAN}${CONFIGURE_FIREWALL}${COLOR_NC}"
print_brake 70
warning "Write down the database password above — it will be needed for recovery."
echo ""

echo -n "* Proceed with the installation? (y/N): "
read -r CONFIRM_INSTALL
if [[ ! "$CONFIRM_INSTALL" =~ [Yy] ]]; then
  abort_install "Installation aborted by user."
fi

export MYSQL_DB MYSQL_USER MYSQL_PASSWORD FQDN TIMEZONE
export USER_EMAIL USER_USERNAME USER_FIRSTNAME USER_LASTNAME USER_PASSWORD
export ASSUME_SSL CONFIGURE_LETSENCRYPT CONFIGURE_FIREWALL LE_EMAIL

run_installer "panel"
