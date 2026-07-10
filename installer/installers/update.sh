#!/bin/bash

########################################################################
#                 Luxodactyl Installer — Panel Updater                 #
#                                                                      #
#  Sourced (via run_installer "update") after ui/update.sh has        #
#  confirmed the target release. Pins the existing install to that   #
#  exact tag, rebuilds it in place, and restarts services.            #
#                                                                      #
#  Expected variables (set by ui/update.sh):                          #
#    UPDATE_TARGET_TAG, UPDATE_TARGET_CHANNEL                         #
########################################################################

maintenance_down() {
  php artisan down --retry=15
}

stop_worker() {
  systemctl stop luxodactyl.service 2>/dev/null || true
}

pull_release() {
  # Root running git against a directory that a previous install already
  # chown'd to www-data trips git's "dubious ownership" safety check.
  ensure_git_safe_directory "$INSTALL_DIR"
  # --tags alone only fetches tags -- also need branch tips updated so a
  # branch name or an arbitrary commit reachable from one actually resolves.
  git fetch --all --tags origin
  git checkout "$UPDATE_TARGET_TAG"

  # Written here (before the frontend build) rather than after, because
  # vite.config.ts reads APP_VERSION/APP_UPDATE_CHANNEL straight out of .env
  # at build time to bake the displayed version into the compiled JS.
  set_env_value APP_VERSION "$UPDATE_TARGET_TAG" "$INSTALL_DIR/.env"
  set_env_value APP_UPDATE_CHANNEL "$UPDATE_TARGET_CHANNEL" "$INSTALL_DIR/.env"
}

install_dependencies() {
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction
}

build_frontend() {
  pnpm install --frozen-lockfile || pnpm install
  pnpm run build
}

run_migrations() {
  php artisan migrate --force
  php artisan config:clear
  php artisan view:clear
  php artisan cache:clear
}

fix_permissions_and_restart() {
  chown -R www-data:www-data "$INSTALL_DIR"
  chmod -R 755 "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache"
  systemctl start luxodactyl.service
  systemctl reload "php${PHP_VERSION}-fpm" 2>/dev/null || systemctl restart "php${PHP_VERSION}-fpm"
}

luxo_panel_update() {
  cd "$INSTALL_DIR" || { error "Panel directory ${INSTALL_DIR} is missing."; exit 1; }

  # No matter how the update goes from here, make sure the panel doesn't get
  # left in maintenance mode -- bring it back up whenever this process exits,
  # for any reason (including a failed step further down). This overrides
  # install.sh's own EXIT trap, so chain its temp-dir cleanup too.
  trap 'php artisan up >/dev/null 2>&1 || true; cleanup_tmp 2>/dev/null || true' EXIT

  spin "Putting the panel into maintenance mode" maintenance_down
  spin "Stopping the queue worker" stop_worker
  spin "Fetching ${UPDATE_TARGET_TAG}" pull_release
  spin "Installing PHP dependencies via Composer" install_dependencies
  spin "Building the frontend (this can take a few minutes)" build_frontend
  spin "Running database migrations" run_migrations
  spin "Setting permissions and restarting services" fix_permissions_and_restart

  echo ""
  print_brake 70
  success "Luxodactyl panel updated to ${UPDATE_TARGET_TAG}!"
  print_brake 70
}

luxo_panel_update
