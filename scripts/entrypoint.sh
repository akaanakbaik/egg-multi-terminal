#!/usr/bin/env bash
set -Eeuo pipefail

source /etc/profile.d/aka-runtime.sh || true

mkdir -p /home/container
cd /home/container

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
info() { c '36' "[aka] $1"; }
warn() { c '33' "[aka] $1"; }

use_node_version() {
  local wanted="${NODE_VERSION:-}"
  if [[ -z "${wanted}" || "${wanted}" == "default" ]]; then
    return 0
  fi
  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    source "${NVM_DIR}/nvm.sh"
    if nvm use "${wanted}" >/dev/null 2>&1; then
      info "Node.js aktif: $(node -v)"
    elif nvm install "${wanted}" >/dev/null 2>&1 && nvm use "${wanted}" >/dev/null 2>&1; then
      info "Node.js berhasil dipasang dan aktif: $(node -v)"
    else
      warn "Gagal memakai NODE_VERSION=${wanted}, fallback ke default: $(node -v 2>/dev/null || echo unknown)"
    fi
  fi
}

start_cloudflare_tunnel() {
  local enabled="${ENABLE_CF_TUNNEL:-false}"
  enabled="${enabled,,}"
  if [[ "${enabled}" != "true" && "${enabled}" != "1" && "${enabled}" != "yes" ]]; then
    return 0
  fi
  if ! command -v cloudflared >/dev/null 2>&1; then
    warn "cloudflared tidak tersedia di image"
    return 0
  fi
  if [[ -n "${CF_TOKEN:-}" ]]; then
    info "Menjalankan Cloudflare Tunnel mode token"
    nohup cloudflared tunnel --no-autoupdate run --token "${CF_TOKEN}" >/home/container/cloudflared.log 2>&1 &
    return 0
  fi
  local url="${CF_URL:-}"
  if [[ -z "${url}" ]]; then
    url="http://127.0.0.1:${APP_PORT:-${SERVER_PORT:-3000}}"
  fi
  info "Menjalankan Cloudflare quick tunnel ke ${url}"
  nohup cloudflared tunnel --no-autoupdate --url "${url}" >/home/container/cloudflared.log 2>&1 &
}

auto_install_dependencies() {
  local enabled="${AUTO_INSTALL_ON_START:-false}"
  enabled="${enabled,,}"
  if [[ "${enabled}" != "true" && "${enabled}" != "1" && "${enabled}" != "yes" ]]; then
    return 0
  fi
  info "Auto install dependency aktif"
  if [[ -f package.json ]]; then
    if [[ -f pnpm-lock.yaml ]] && command -v pnpm >/dev/null 2>&1; then pnpm install --prod || true;
    elif [[ -f yarn.lock ]] && command -v yarn >/dev/null 2>&1; then yarn install --production || true;
    elif [[ -f bun.lockb || -f bun.lock ]] && command -v bun >/dev/null 2>&1; then bun install --production || true;
    else npm install --omit=dev || npm install --production || true; fi
  fi
  if [[ -f requirements.txt ]]; then
    if command -v pip >/dev/null 2>&1; then pip install -r requirements.txt || true; else python3 -m pip install --break-system-packages -r requirements.txt || true; fi
  fi
  if [[ -f composer.json ]] && command -v composer >/dev/null 2>&1; then composer install --no-dev --no-interaction || composer install --no-interaction || true; fi
  if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then go mod download || true; fi
  if [[ -f Gemfile ]] && command -v bundle >/dev/null 2>&1; then bundle install || true; fi
}

detect_startup_command() {
  if [[ -f package.json ]]; then
    if command -v jq >/dev/null 2>&1 && jq -e '.scripts.start' package.json >/dev/null 2>&1; then echo "npm start"; return 0; fi
    if [[ -f index.js ]]; then echo "node index.js"; return 0; fi
    if [[ -f src/index.js ]]; then echo "node src/index.js"; return 0; fi
    if [[ -f server.js ]]; then echo "node server.js"; return 0; fi
    if [[ -f app.js ]]; then echo "node app.js"; return 0; fi
  fi
  if [[ -f main.py ]]; then echo "python3 main.py"; return 0; fi
  if [[ -f bot.py ]]; then echo "python3 bot.py"; return 0; fi
  if [[ -f app.py ]]; then echo "python3 app.py"; return 0; fi
  if [[ -f artisan ]]; then echo "php artisan serve --host=0.0.0.0 --port=${APP_PORT:-${SERVER_PORT:-8000}}"; return 0; fi
  if [[ -f index.php ]]; then echo "php -S 0.0.0.0:${APP_PORT:-${SERVER_PORT:-8000}}"; return 0; fi
  echo "bash"
}

use_node_version

if [[ "${AKA_SHOW_INFO:-1}" == "1" ]]; then
  aka-info || true
fi

auto_install_dependencies
start_cloudflare_tunnel

STARTUP_COMMAND="${STARTUP_CMD:-bash}"
if [[ "${STARTUP_COMMAND}" == "auto" ]]; then
  STARTUP_COMMAND="$(detect_startup_command)"
  info "Auto startup terdeteksi: ${STARTUP_COMMAND}"
fi

if [[ "$#" -gt 0 && "$1" != "bash" ]]; then
  exec "$@"
fi

case "${STARTUP_COMMAND}" in
  ""|"bash"|"/bin/bash"|"bash -i"|"/bin/bash -i")
    exec /bin/bash -i
    ;;
  *)
    info "Menjalankan STARTUP_CMD: ${STARTUP_COMMAND}"
    exec /bin/bash -lc "${STARTUP_COMMAND}"
    ;;
esac
