#!/bin/bash

########################################################################
#                Luxodactyl Installer — Wings Installer                #
#                                                                      #
#  Installs Docker and the Pterodactyl Wings daemon. Sourced via      #
#  run_installer "wings" from ui/wings.sh.                            #
#                                                                      #
#  Expected variables (set by ui/wings.sh):                           #
#    CONFIGURE_FIREWALL                                                #
########################################################################

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    output "Docker is already installed — skipping."
    return 0
  fi
  output "Installing Docker..."
  curl -sSL https://get.docker.com/ | CHANNEL=stable bash
  systemctl enable --now docker
}

install_wings_binary() {
  output "Creating Wings directories..."
  mkdir -p /etc/pterodactyl /var/log/pterodactyl

  output "Downloading the Wings binary (${ARCH})..."
  curl -L -o /usr/local/bin/wings \
    "${WINGS_DL_BASE_URL}/latest/download/wings_linux_${ARCH}"
  chmod u+x /usr/local/bin/wings
}

install_wings_service() {
  output "Creating the Wings systemd service..."
  cat >/etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable wings
}

wings_firewall() {
  [ "$CONFIGURE_FIREWALL" != true ] && return 0
  install_firewall
  firewall_allow_ports "22 8080 2022"
  success "Firewall configured for Wings (ports 22, 8080, 2022 open)."
}

luxo_wings_install() {
  check_root
  check_os_supported
  check_virt

  update_repos
  install_packages "curl tar unzip git"

  install_docker
  install_wings_binary
  install_wings_service
  wings_firewall

  echo ""
  print_brake 70
  success "Wings installed successfully!"
  output "Next steps:"
  output "  1. In the panel admin area, create a Node and copy its configuration."
  output "  2. Save it to ${COLOR_CYAN}/etc/pterodactyl/config.yml${COLOR_NC}"
  output "  3. Start Wings: ${COLOR_CYAN}systemctl start wings${COLOR_NC}"
  print_brake 70
}

luxo_wings_install
