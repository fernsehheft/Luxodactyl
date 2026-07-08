#!/bin/bash

# ==========================================
# Luxodactyl/Luxodactyl Installation Wizard
# ==========================================
# Supported OS: Ubuntu 22.04, Ubuntu 24.04, Debian 11, Debian 12
# Built for PHP 8.4 & Nginx & Wings

set -e

# Visual Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0;37m' # No Color
BOLD='\033[1m'

# Log helpers
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root Check
if [ "$EUID" -ne 0 ]; then
    log_error "Dieses Skript muss als Root-Benutzer ausgeführt werden (sudo -i)."
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    log_error "Konnte das Betriebssystem nicht identifizieren."
    exit 1
fi

# Check OS compatibility
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    log_error "Dieses Skript unterstützt derzeit nur Ubuntu und Debian."
    exit 1
fi

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e "${CYAN}${BOLD}           __Hydr0dactyl / Luxodactyl Installation Wizard__         ${NC}"
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e "  Betriebssystem: ${MAGENTA}$NAME $VERSION_ID${NC}"
    echo -e "  Dieses Skript hilft dir bei der Installation des Panels und Wings."
    echo -e "${CYAN}====================================================================${NC}"
}

show_menu() {
    echo -e "\n${BOLD}Bitte wähle eine Option aus:${NC}"
    echo -e "  1) ${CYAN}Luxodactyl Panel${NC} installieren"
    echo -e "  2) ${CYAN}Pterodactyl Wings (Daemon)${NC} installieren"
    echo -e "  3) ${CYAN}Beides (Panel & Wings)${NC} auf diesem Server installieren"
    echo -e "  4) Let's Encrypt SSL-Zertifikat konfigurieren"
    echo -e "  5) Installation abbrechen"
    echo -e ""
    read -p "Option [1-5]: " OPTION
}

# Helper to generate passwords
generate_password() {
    openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16
}

install_dependencies() {
    log_info "Aktualisiere Systempakete..."
    apt-get update -y && apt-get upgrade -y

    log_info "Installiere grundlegende Tools (curl, git, unzip, certbot)..."
    apt-get install -y curl git unzip tar certbot python3-certbot-nginx ca-certificates gnupg

    # Install MariaDB
    log_info "Installiere MariaDB Server..."
    apt-get install -y mariadb-server mariadb-client
    systemctl enable mariadb
    systemctl start mariadb

    # Install Redis
    log_info "Installiere Redis..."
    apt-get install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server

    # Setup PHP repository
    log_info "Richte PHP 8.4 Repository ein..."
    if [ "$OS" == "ubuntu" ]; then
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:ondrej/php
    elif [ "$OS" == "debian" ]; then
        curl -sSL https://packages.sury.org/php/README.txt | bash
    fi

    apt-get update -y

    # Install PHP 8.4 packages
    log_info "Installiere PHP 8.4 und Erweiterungen..."
    apt-get install -y php8.4 php8.4-cli php8.4-gd php8.4-mysql php8.4-mbstring php8.4-bcmath \
        php8.4-xml php8.4-curl php8.4-zip php8.4-fpm php8.4-sqlite3 php8.4-redis
    
    systemctl enable php8.4-fpm
    systemctl start php8.4-fpm

    # Install Composer
    log_info "Installiere Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    # Install Nginx
    log_info "Installiere Nginx Webserver..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
}

setup_database() {
    log_info "Konfiguriere MariaDB Datenbank..."
    DB_NAME="luxodactyl"
    DB_USER="luxodactyl"
    DB_PASS=$(generate_password)

    mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;"
    mysql -e "FLUSH PRIVILEGES;"

    log_success "Datenbank wurde erfolgreich eingerichtet!"
    echo -e "  Datenbank-Name: ${GREEN}${DB_NAME}${NC}"
    echo -e "  Datenbank-User: ${GREEN}${DB_USER}${NC}"
    echo -e "  Datenbank-Passwort: ${GREEN}${DB_PASS}${NC}"
    echo -e "${YELLOW}Bitte notiere dir diese Zugangsdaten!${NC}"
}

setup_panel() {
    log_info "Richte das Luxodactyl Panel unter /var/www/luxodactyl ein..."
    mkdir -p /var/www/luxodactyl
    cd /var/www/luxodactyl

    # Clone luxodactyl repository
    log_info "Klone Repository..."
    git clone https://github.com/fernsehheft/Luxodactyl.git .
    git checkout main

    # Copy env and set permissions
    cp .env.example .env

    log_info "Installiere Composer-Abhängigkeiten..."
    composer install --no-dev --optimize-autoloader --no-interaction

    # Install Node.js & pnpm and compile frontend
    log_info "Installiere Node.js und pnpm..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    npm install -g corepack@latest pnpm
    corepack enable

    log_info "Kompiliere Frontend-Assets (Redesign)..."
    pnpm install
    pnpm run build

    # Generate app key
    php artisan key:generate --force

    # Fill .env configuration
    log_info "Bitte gib die FQDN/Domain für dein Panel ein (z.B. panel.deine-domain.de):"
    read -p "Domain: " PANEL_URL
    
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/g" .env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USER}/g" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/g" .env
    sed -i "s#APP_URL=.*#APP_URL=https://${PANEL_URL}#g" .env

    # Set timezone
    log_info "Bitte Zeitzone eingeben (z.B. Europe/Berlin):"
    read -p "Zeitzone [Europe/Berlin]: " TIMEZONE
    if [ -z "$TIMEZONE" ]; then
        TIMEZONE="Europe/Berlin"
    fi
    sed -i "s#APP_TIMEZONE=.*#APP_TIMEZONE=${TIMEZONE}#g" .env

    # Run Migrations
    log_info "Führe Datenbank-Migrationen aus..."
    php artisan migrate --seed --force

    # Create admin user
    log_info "Erstelle den Administrator-Account..."
    php artisan p:user:make --admin

    # Set permissions
    chown -R www-data:www-data /var/www/luxodactyl/*
    chmod -R 755 bootstrap/cache storage

    # Install Queue Worker
    log_info "Erstelle systemd Service für den Queue-Worker..."
    cat <<EOF > /etc/systemd/system/luxodactyl.service
[Unit]
Description=Luxodactyl Queue Worker
After=network.target

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/luxodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now luxodactyl.service

    # Setup Cronjob
    log_info "Richte Cronjob für den Laravel Scheduler ein..."
    (crontab -u www-data -l 2>/dev/null; echo "* * * * * /usr/bin/php /var/www/luxodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -

    # Setup Nginx Configuration
    log_info "Erstelle Nginx-Konfiguration..."
    cat <<EOF > /etc/nginx/sites-available/luxodactyl.conf
server {
    listen 80;
    server_name ${PANEL_URL};
    
    root /var/www/luxodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/luxodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
  
    sendfile off;

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
    
    location ~/\.git {
        deny all;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/luxodactyl.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    systemctl restart nginx

    # SSL Setup options
    setup_ssl "$PANEL_URL"
}

setup_ssl() {
    local domain=$1
    echo ""
    log_info "Möchtest du jetzt ein kostenloses Let's Encrypt SSL-Zertifikat für $domain konfigurieren? (y/n)"
    read -p "[y/n]: " SSL_CHOICE
    if [[ "$SSL_CHOICE" == "y" || "$SSL_CHOICE" == "Y" ]]; then
        log_info "Fordere SSL-Zertifikat von Let's Encrypt für $domain an..."
        certbot --nginx -d "$domain" --non-interactive --agree-tos --register-unsafely-without-email
        log_success "SSL-Zertifikat erfolgreich installiert!"
    else
        log_warning "SSL wurde nicht konfiguriert. Du solltest es später manuell einrichten."
    fi
}

install_wings() {
    log_info "Installiere Docker..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable docker
    systemctl start docker

    log_info "Erstelle Verzeichnisse für Wings..."
    mkdir -p /etc/pterodactyl /var/log/pterodactyl

    log_info "Lade Wings-Binary herunter..."
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
    chmod +x /usr/local/bin/wings

    log_info "Erstelle systemd Service für Wings..."
    cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=1048576
LimitNPROC=512
LimitMEMLOCK=infinity
TasksMax=infinity
OOMScoreAdjust=-1000
ExecStart=/usr/local/bin/wings
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable wings.service
    log_success "Wings wurde erfolgreich installiert! Bitte füge den Node im Admin-Interface hinzu und kopiere die Konfiguration nach /etc/pterodactyl/config.yml, starte dann Wings mit 'systemctl start wings'."
}

ssl_only_wizard() {
    log_info "Bitte gib die Domain ein, für die du SSL konfigurieren möchtest:"
    read -p "Domain: " DOMAIN
    setup_ssl "$DOMAIN"
}

# Main execution flow
show_banner
show_menu

case $OPTION in
    1)
        log_info "Starte Luxodactyl Panel Installation..."
        install_dependencies
        setup_database
        setup_panel
        log_success "Installation des Panels abgeschlossen!"
        ;;
    2)
        log_info "Starte Wings Installation..."
        install_wings
        log_success "Installation von Wings abgeschlossen!"
        ;;
    3)
        log_info "Starte Komplett-Installation (Panel & Wings)..."
        install_dependencies
        setup_database
        setup_panel
        install_wings
        log_success "Komplett-Installation erfolgreich abgeschlossen!"
        ;;
    4)
        ssl_only_wizard
        ;;
    5)
        log_info "Installation abgebrochen."
        exit 0
        ;;
    *)
        log_error "Ungültige Option ausgewählt."
        exit 1
        ;;
esac
