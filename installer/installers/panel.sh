#!/bin/bash

########################################################################
#                 Luxodactyl Installer — Panel Installer               #
#                                                                      #
#  Sourced (via run_installer "panel") after ui/panel.sh has          #
#  collected all configuration variables.                             #
#                                                                      #
#  Expected variables (set by ui/panel.sh):                           #
#    MYSQL_DB, MYSQL_USER, MYSQL_PASSWORD                              #
#    FQDN, TIMEZONE                                                    #
#    ADMIN_EMAIL                                                       #
#    USER_EMAIL, USER_USERNAME, USER_FIRSTNAME, USER_LASTNAME,        #
#    USER_PASSWORD                                                     #
#    ASSUME_SSL, CONFIGURE_LETSENCRYPT, CONFIGURE_FIREWALL            #
########################################################################

# --------------------------------------------------------------------- #
#                            Dependencies                               #
# --------------------------------------------------------------------- #
install_composer() {
  output "Installing Composer..."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
}

install_php() {
  output "Setting up the PHP ${PHP_VERSION} repository..."
  if [ "$OS" == "ubuntu" ]; then
    install_packages "software-properties-common ca-certificates lsb-release apt-transport-https gnupg"
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
  elif [ "$OS" == "debian" ]; then
    install_packages "ca-certificates apt-transport-https lsb-release gnupg"
    curl -sSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/sury-php.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/sury-php.list
  fi

  update_repos

  output "Installing PHP ${PHP_VERSION} and extensions..."
  install_packages "php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-zip \
    php${PHP_VERSION}-fpm php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-redis \
    php${PHP_VERSION}-intl"

  systemctl enable --now "php${PHP_VERSION}-fpm"
}

install_nodejs() {
  output "Installing Node.js 22 and pnpm (required to build the panel frontend)..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  install_packages "nodejs"
  npm install -g corepack@latest
  corepack enable
  corepack prepare pnpm@latest --activate
}

install_mariadb() {
  output "Installing MariaDB server..."
  install_packages "mariadb-server mariadb-client"
  systemctl enable --now mariadb
}

install_redis() {
  output "Installing Redis..."
  install_packages "redis-server"
  systemctl enable --now redis-server
}

install_nginx() {
  output "Installing Nginx web server..."
  install_packages "nginx"
  systemctl enable nginx
}

dep_install() {
  output "Installing dependencies for ${OS} ${OS_VER}..."
  update_repos
  install_packages "curl git unzip tar cron"

  install_mariadb
  install_redis
  install_php
  install_composer
  install_nginx
  install_nodejs

  success "Dependencies installed."
}

# --------------------------------------------------------------------- #
#                              Database                                 #
# --------------------------------------------------------------------- #
configure_database() {
  output "Configuring MariaDB database..."
  create_db_user "$MYSQL_USER" "$MYSQL_PASSWORD"
  create_db "$MYSQL_DB" "$MYSQL_USER"
  success "Database configured."
}

# --------------------------------------------------------------------- #
#                          Panel installation                          #
# --------------------------------------------------------------------- #
panel_dl() {
  output "Downloading Luxodactyl to ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR" || exit 1

  if [ -d "$INSTALL_DIR/.git" ]; then
    git fetch --all
    git checkout "$LUXO_BRANCH"
    git pull origin "$LUXO_BRANCH"
  else
    git clone --branch "$LUXO_BRANCH" "$LUXO_REPO" .
  fi

  cp .env.example .env

  output "Installing PHP dependencies via Composer..."
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction

  output "Building the frontend (this can take a few minutes)..."
  pnpm install --frozen-lockfile || pnpm install
  pnpm run build

  php artisan key:generate --force
}

configure_environment() {
  output "Configuring the panel environment (.env)..."

  local app_url="http://$FQDN"
  [ "$ASSUME_SSL" == true ] && app_url="https://$FQDN"

  php artisan p:environment:setup \
    --author="$ADMIN_EMAIL" \
    --url="$app_url" \
    --timezone="$TIMEZONE" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="127.0.0.1" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui=true

  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$MYSQL_DB" \
    --username="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD"

  output "Running database migrations and seeders..."
  php artisan migrate --seed --force

  output "Creating the administrator account..."
  php artisan p:user:make \
    --email="$USER_EMAIL" \
    --username="$USER_USERNAME" \
    --name-first="$USER_FIRSTNAME" \
    --name-last="$USER_LASTNAME" \
    --password="$USER_PASSWORD" \
    --admin=1
}

set_permissions() {
  output "Setting file permissions..."
  chown -R www-data:www-data "$INSTALL_DIR"
  chmod -R 755 "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache"
}

# --------------------------------------------------------------------- #
#                        Services (queue + cron)                        #
# --------------------------------------------------------------------- #
install_services() {
  output "Creating the queue worker systemd service..."
  cat >/etc/systemd/system/luxodactyl.service <<EOF
[Unit]
Description=Luxodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php ${INSTALL_DIR}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now luxodactyl.service

  output "Installing the Laravel scheduler cronjob..."
  if ! crontab -l -u www-data 2>/dev/null | grep -q "artisan schedule:run"; then
    (crontab -l -u www-data 2>/dev/null; echo "* * * * * /usr/bin/php ${INSTALL_DIR}/artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -
  fi
}

# --------------------------------------------------------------------- #
#                                Nginx                                  #
# --------------------------------------------------------------------- #
configure_nginx() {
  output "Configuring Nginx for ${FQDN}..."
  rm -f /etc/nginx/sites-enabled/default

  local php_socket="/run/php/php${PHP_VERSION}-fpm.sock"
  local config_path="/etc/nginx/sites-available/luxodactyl.conf"

  if [ "$ASSUME_SSL" == true ] || [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    write_nginx_ssl "$config_path" "$php_socket"
  else
    write_nginx_plain "$config_path" "$php_socket"
  fi

  ln -sf "$config_path" /etc/nginx/sites-enabled/luxodactyl.conf
}

write_nginx_plain() {
  cat >"$1" <<EOF
server {
    listen 80;
    server_name ${FQDN};

    root ${INSTALL_DIR}/public;
    index index.php;

    access_log /var/log/nginx/luxodactyl.app-access.log;
    error_log  /var/log/nginx/luxodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${2};
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

    location ~ /\.ht { deny all; }
}
EOF
}

write_nginx_ssl() {
  cat >"$1" <<EOF
server_tokens off;

server {
    listen 80;
    server_name ${FQDN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FQDN};

    root ${INSTALL_DIR}/public;
    index index.php;

    access_log /var/log/nginx/luxodactyl.app-access.log;
    error_log  /var/log/nginx/luxodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    ssl_certificate     /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${2};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param HTTPS on;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht { deny all; }
}
EOF
}

# --------------------------------------------------------------------- #
#                                 SSL                                   #
# --------------------------------------------------------------------- #
letsencrypt() {
  [ "$CONFIGURE_LETSENCRYPT" != true ] && return 0

  output "Obtaining a Let's Encrypt certificate for ${FQDN}..."
  install_packages "certbot python3-certbot-nginx"

  # Nginx must be able to start with a working config first; the SSL
  # server block references certs that don't exist yet, so we obtain
  # the cert in webroot/standalone-friendly nginx mode.
  systemctl stop nginx || true
  if certbot certonly --standalone -d "$FQDN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"; then
    success "SSL certificate obtained."
  else
    warning "Failed to obtain an SSL certificate. The panel will run on HTTP until you configure SSL manually."
    ASSUME_SSL=false
    CONFIGURE_LETSENCRYPT=false
    configure_nginx
  fi
  systemctl start nginx || true
}

# --------------------------------------------------------------------- #
#                               Firewall                                #
# --------------------------------------------------------------------- #
firewall() {
  [ "$CONFIGURE_FIREWALL" != true ] && return 0
  install_firewall
  firewall_allow_ports "22 80 443"
  success "Firewall configured (ports 22, 80, 443 open)."
}

# --------------------------------------------------------------------- #
#                                 Main                                  #
# --------------------------------------------------------------------- #
luxo_panel_install() {
  dep_install
  configure_database
  panel_dl
  configure_environment
  set_permissions
  install_services
  configure_nginx
  letsencrypt
  firewall

  systemctl restart nginx

  local proto="http"
  [ "$ASSUME_SSL" == true ] && proto="https"

  echo ""
  print_brake 70
  success "Luxodactyl panel installed successfully!"
  output "Access your panel at: ${COLOR_CYAN}${proto}://${FQDN}${COLOR_NC}"
  output "Admin login: ${USER_EMAIL}"
  print_brake 70
}

luxo_panel_install
