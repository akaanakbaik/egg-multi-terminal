#!/usr/bin/env bash
set -Ee -o pipefail

AKA_HOME="${HOME:-/home/container}"
export HOME="$AKA_HOME"
export NVM_DIR="${NVM_DIR:-/usr/local/nvm}"
export TERM="${TERM:-xterm-256color}"
export PATH="${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"

if [ -r /etc/profile.d/aka-runtime.sh ]; then
  . /etc/profile.d/aka-runtime.sh >/dev/null 2>&1 || true
fi

mkdir -p /home/container
cd /home/container || cd /tmp

c() { printf '\033[%sm%s\033[0m\n' "${1:-0}" "${2:-}"; }
info() { c '36' "[aka] ${1:-}"; }
warn() { c '33' "[aka] ${1:-}"; }
istrue() {
  case "${1:-}" in
    true|TRUE|True|1|yes|YES|Yes|on|ON|On) return 0 ;;
    *) return 1 ;;
  esac
}

use_node_version() {
  local wanted="${NODE_VERSION:-}"
  [ -z "$wanted" ] && return 0
  [ "$wanted" = "default" ] && return 0
  [ ! -s "${NVM_DIR}/nvm.sh" ] && return 0
  . "${NVM_DIR}/nvm.sh" >/dev/null 2>&1 || return 0
  if nvm use "$wanted" >/dev/null 2>&1; then
    info "Node.js aktif: $(node -v 2>/dev/null || echo unknown)"
  elif nvm install "$wanted" >/dev/null 2>&1 && nvm use "$wanted" >/dev/null 2>&1; then
    info "Node.js berhasil dipasang: $(node -v 2>/dev/null || echo unknown)"
  else
    warn "NODE_VERSION=$wanted gagal, fallback ke default"
  fi
}

start_cloudflare_tunnel() {
  istrue "${ENABLE_CF_TUNNEL:-false}" || return 0
  command -v cloudflared >/dev/null 2>&1 || { warn "cloudflared tidak tersedia"; return 0; }
  if [ -n "${CF_TOKEN:-}" ]; then
    info "Menjalankan Cloudflare Tunnel mode token"
    nohup cloudflared tunnel --no-autoupdate run --token "${CF_TOKEN}" >/home/container/cloudflared.log 2>&1 &
    return 0
  fi
  local url="${CF_URL:-}"
  [ -z "$url" ] && url="http://127.0.0.1:${APP_PORT:-${SERVER_PORT:-3000}}"
  info "Menjalankan Cloudflare quick tunnel ke $url"
  nohup cloudflared tunnel --no-autoupdate --url "$url" >/home/container/cloudflared.log 2>&1 &
}

auto_install_dependencies() {
  istrue "${AUTO_INSTALL_ON_START:-false}" || return 0
  info "Auto install dependency aktif"
  if [ -f package.json ]; then
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then pnpm install --prod || true
    elif [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then yarn install --production || true
    elif { [ -f bun.lockb ] || [ -f bun.lock ]; } && command -v bun >/dev/null 2>&1; then bun install --production || true
    else npm install --omit=dev || npm install --production || true
    fi
  fi
  if [ -f requirements.txt ]; then
    if command -v pip >/dev/null 2>&1; then pip install -r requirements.txt || true
    else python3 -m pip install --break-system-packages -r requirements.txt || true
    fi
  fi
  [ -f composer.json ] && command -v composer >/dev/null 2>&1 && { composer install --no-dev --no-interaction || composer install --no-interaction || true; }
  [ -f go.mod ] && command -v go >/dev/null 2>&1 && { go mod download || true; }
  [ -f Gemfile ] && command -v bundle >/dev/null 2>&1 && { bundle install || true; }
}

detect_startup_command() {
  if [ -f package.json ]; then
    if command -v jq >/dev/null 2>&1 && jq -e '.scripts.start' package.json >/dev/null 2>&1; then echo "npm start"; return 0; fi
    [ -f index.js ] && { echo "node index.js"; return 0; }
    [ -f src/index.js ] && { echo "node src/index.js"; return 0; }
    [ -f server.js ] && { echo "node server.js"; return 0; }
    [ -f app.js ] && { echo "node app.js"; return 0; }
  fi
  [ -f main.py ] && { echo "python3 main.py"; return 0; }
  [ -f bot.py ] && { echo "python3 bot.py"; return 0; }
  [ -f app.py ] && { echo "python3 app.py"; return 0; }
  [ -f artisan ] && { echo "php artisan serve --host=0.0.0.0 --port=${APP_PORT:-${SERVER_PORT:-8000}}"; return 0; }
  [ -f index.php ] && { echo "php -S 0.0.0.0:${APP_PORT:-${SERVER_PORT:-8000}}"; return 0; }
  echo "bash"
}

use_node_version || true

if istrue "${AKA_SHOW_INFO:-1}"; then
  if [ "${AKA_INFO_MODE:-compact}" = "full" ]; then
    aka-info || true
  else
    aka-info --compact || aka-info || true
  fi
fi

auto_install_dependencies || true
start_cloudflare_tunnel || true

STARTUP_COMMAND="${STARTUP_CMD:-bash}"
if [ "$STARTUP_COMMAND" = "auto" ]; then
  STARTUP_COMMAND="$(detect_startup_command)"
  info "Auto startup: $STARTUP_COMMAND"
fi

if [ "$#" -gt 0 ] && [ "${1:-}" != "bash" ]; then
  exec "$@"
fi

case "$STARTUP_COMMAND" in
  ""|"bash"|"/bin/bash"|"bash -i"|"/bin/bash -i")
    exec /bin/bash -i
    ;;
  *)
    info "Menjalankan: $STARTUP_COMMAND"
    exec /bin/bash -lc "$STARTUP_COMMAND"
    ;;
esac
