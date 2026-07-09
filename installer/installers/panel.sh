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
#    USER_EMAIL, USER_USERNAME, USER_FIRSTNAME, USER_LASTNAME,        #
#    USER_PASSWORD                                                     #
#    ASSUME_SSL, CONFIGURE_LETSENCRYPT, CONFIGURE_FIREWALL            #
#    LE_EMAIL (only when CONFIGURE_LETSENCRYPT=true)                  #
########################################################################

# --------------------------------------------------------------------- #
#                            Dependencies                               #
# --------------------------------------------------------------------- #
install_composer() {
  if command -v composer >/dev/null 2>&1; then
    output "Composer already installed — skipping."
    return
  fi
  output "Installing Composer..."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
}

install_php() {
  # Skip the (slow) repository setup if PHP is already present; still run the
  # package install below so any missing extensions get added.
  if command -v "php${PHP_VERSION}" >/dev/null 2>&1; then
    output "PHP ${PHP_VERSION} already installed — skipping repository setup, verifying extensions."
  else
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
  fi

  output "Installing PHP ${PHP_VERSION} and extensions..."
  install_packages "php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-zip \
    php${PHP_VERSION}-fpm php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-redis \
    php${PHP_VERSION}-intl"

  systemctl enable --now "php${PHP_VERSION}-fpm"
}

install_nodejs() {
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  if command -v node >/dev/null 2>&1; then
    output "Node.js already installed ($(node -v 2>/dev/null)) — skipping, ensuring pnpm is available."
  else
    output "Installing Node.js 22 (required to build the panel frontend)..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    install_packages "nodejs"
    npm install -g corepack@latest
  fi
  corepack enable
  corepack prepare pnpm@latest --activate
}

install_mariadb() {
  if command -v mariadb >/dev/null 2>&1 || command -v mysql >/dev/null 2>&1; then
    output "MariaDB/MySQL already installed — skipping install, ensuring it runs."
    systemctl enable --now mariadb 2>/dev/null || systemctl enable --now mysql 2>/dev/null || true
    return
  fi
  output "Installing MariaDB server..."
  install_packages "mariadb-server mariadb-client"
  systemctl enable --now mariadb
}

install_redis() {
  if command -v redis-server >/dev/null 2>&1; then
    output "Redis already installed — skipping install, ensuring it runs."
    systemctl enable --now redis-server 2>/dev/null || true
    return
  fi
  output "Installing Redis..."
  install_packages "redis-server"
  systemctl enable --now redis-server
}

install_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    output "Nginx already installed — skipping install."
    systemctl enable nginx 2>/dev/null || true
    return
  fi
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

  # Create the user for BOTH '127.0.0.1' and 'localhost'. MariaDB resolves
  # 127.0.0.1 back to the hostname 'localhost' (unless skip-name-resolve is
  # set), so a user created only for '127.0.0.1' fails with
  # "Access denied for 'user'@'localhost'". We also ALTER the password so
  # re-running the installer updates an existing user instead of leaving a
  # stale password behind.
  mysql -u root <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DB};
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

  success "Database configured."
}

# --------------------------------------------------------------------- #
#                          Panel installation                          #
# --------------------------------------------------------------------- #
panel_dl() {
  # Complete reinstall: stop the worker and wipe the old panel files so we
  # get a clean checkout. The database is intentionally left untouched so
  # existing servers/users survive; drop it manually for a truly blank slate.
  if [ "${REINSTALL:-false}" == true ] && [ -d "$INSTALL_DIR" ]; then
    output "Reinstall: removing the existing panel at ${INSTALL_DIR} (database is kept)..."
    systemctl stop luxodactyl.service 2>/dev/null || true
    rm -rf "$INSTALL_DIR"
  fi

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

  # Generate the application key WITHOUT invoking artisan. On this fork
  # (Laravel 13) some service providers resolve the encrypter while the
  # framework boots, so `artisan key:generate` fails with
  # "No application encryption key has been specified" when the key is
  # still empty. Writing a valid base64 key straight into .env avoids
  # that chicken-and-egg situation; every later artisan command then
  # boots cleanly.
  output "Generating the application key..."
  local app_key="base64:$(openssl rand -base64 32)"
  sed -i "s#^APP_KEY=.*#APP_KEY=${app_key}#" .env

  # Hashids salt ships empty in .env.example; set it here so we don't
  # depend on the artisan bootstrap generating it.
  local hashids_salt
  hashids_salt="$(openssl rand -hex 20)"
  sed -i "s#^HASHIDS_SALT=.*#HASHIDS_SALT=${hashids_salt}#" .env
}

configure_environment() {
  # Ensure we are in the panel directory: this runs in its own subshell
  # under spin(), so it can't rely on a cd made by panel_dl.
  cd "$INSTALL_DIR" || { error "Panel directory ${INSTALL_DIR} is missing."; return 1; }

  output "Configuring the panel environment (.env)..."

  local app_url="http://$FQDN"
  [ "$ASSUME_SSL" == true ] && app_url="https://$FQDN"

  php artisan p:environment:setup \
    --author="$USER_EMAIL" \
    --url="$app_url" \
    --timezone="$TIMEZONE" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="127.0.0.1" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui=true \
    --no-interaction

  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$MYSQL_DB" \
    --username="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --no-interaction

  output "Running database migrations and seeders..."
  php artisan migrate --seed --force

  # Only create the admin if that email/username isn't already present. On a
  # reinstall the database is kept, so the account from a previous run may
  # still exist — creating it again would fail with "email already taken".
  local existing
  existing="$(mysql -u root -N -B -D "${MYSQL_DB}" \
    -e "SELECT COUNT(*) FROM users WHERE email='${USER_EMAIL}' OR username='${USER_USERNAME}';" 2>/dev/null | tr -dc '0-9')"
  [ -z "$existing" ] && existing=0

  if [ "$existing" -gt 0 ]; then
    warning "An account with email '${USER_EMAIL}' or username '${USER_USERNAME}' already exists — skipping admin creation."
  else
    output "Creating the administrator account..."
    # NOTE: --admin is a boolean flag (no value); passing --admin=1 errors out.
    php artisan p:user:make \
      --email="$USER_EMAIL" \
      --username="$USER_USERNAME" \
      --name-first="$USER_FIRSTNAME" \
      --name-last="$USER_LASTNAME" \
      --password="$USER_PASSWORD" \
      --admin \
      --no-interaction
  fi
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

  # Make sure the domain points here before asking Let's Encrypt for a cert.
  wait_for_dns "$FQDN"

  # Cloudflare (or any reverse proxy): the record points at the proxy, so a
  # standalone HTTP-01 challenge can't reach this server. Offer to skip the
  # local certificate and let the proxy terminate SSL.
  local resolved
  resolved="$(get_dns_ip "$FQDN")"
  if [ -n "$resolved" ] && is_cloudflare_ip "$resolved"; then
    echo ""
    warning "${FQDN} points to Cloudflare (proxy enabled)."
    echo -n "* Skip the local Let's Encrypt certificate and let Cloudflare handle SSL? (Y/n): "
    read -r CF_ANS
    if [[ ! "$CF_ANS" =~ [Nn] ]]; then
      warning "Skipping local certificate. In Cloudflare, set SSL/TLS mode to 'Flexible' (origin is HTTP) so visitors still get HTTPS."
      switch_nginx_to_http
      return 0
    fi
    output "Continuing with Let's Encrypt — this will only work if the record is set to 'DNS only' (grey cloud)."
  fi

  output "Obtaining a Let's Encrypt certificate for ${FQDN}..."
  install_packages "certbot python3-certbot-nginx"

  # Nginx must free port 80 for the standalone HTTP-01 challenge.
  systemctl stop nginx || true

  if certbot certonly --standalone -d "$FQDN" --non-interactive --agree-tos -m "$LE_EMAIL"; then
    success "SSL certificate obtained."
  else
    # A stale/unknown ACME account (common after re-installs) shows up as
    # "The account could not be found". Reset it and try once more.
    warning "certbot failed — resetting the Let's Encrypt account and retrying..."
    rm -rf /etc/letsencrypt/accounts 2>/dev/null || true
    if certbot certonly --standalone -d "$FQDN" --non-interactive --agree-tos -m "$LE_EMAIL"; then
      success "SSL certificate obtained after resetting the account."
    else
      warning "Could not obtain an SSL certificate. Falling back to HTTP — configure SSL later."
      switch_nginx_to_http
    fi
  fi
  systemctl start nginx || true
}

# Reconfigure Nginx to plain HTTP (used when SSL is skipped or fails) so the
# server block never references certificates that don't exist.
switch_nginx_to_http() {
  ASSUME_SSL=false
  CONFIGURE_LETSENCRYPT=false
  write_nginx_plain "/etc/nginx/sites-available/luxodactyl.conf" "/run/php/php${PHP_VERSION}-fpm.sock"
  ln -sf /etc/nginx/sites-available/luxodactyl.conf /etc/nginx/sites-enabled/luxodactyl.conf
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
  echo ""
  spin "Installing dependencies (PHP ${PHP_VERSION}, MariaDB, Redis, Nginx, Node.js)" dep_install
  spin "Configuring the database" configure_database
  spin "Downloading and building the panel (this can take a few minutes)" panel_dl
  spin "Configuring environment and running migrations" configure_environment
  spin "Setting file permissions" set_permissions
  spin "Installing services (queue worker + scheduler)" install_services
  spin "Configuring Nginx" configure_nginx

  # These may print meaningful output / need port 80, so run them normally.
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
