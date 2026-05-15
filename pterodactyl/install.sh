#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[aka-installer]${NC} $1"; }
warn() { echo -e "${YELLOW}[aka-installer]${NC} $1"; }

echo "================================================"
echo "        AKA MULTI TERMINAL INSTALLATION"
echo "================================================"

apt-get update
apt-get install -y git curl jq file unzip make gcc g++ python3 python3-pip ca-certificates

mkdir -p /mnt/server
cd /mnt/server

if [ "${USER_UPLOAD}" = "true" ] || [ "${USER_UPLOAD}" = "1" ]; then
    log "User upload mode aktif. Git clone dilewati."
    log "Upload file lewat SFTP/File Manager Pterodactyl."
    exit 0
fi

if [ -z "${GIT_ADDRESS}" ]; then
    log "GIT_ADDRESS kosong. Server siap untuk terminal-only atau upload manual."
    exit 0
fi

case "${GIT_ADDRESS}" in
    *.git) true ;;
    *) GIT_ADDRESS="${GIT_ADDRESS}.git" ;;
esac

if [ -n "${USERNAME}" ] && [ -n "${ACCESS_TOKEN}" ]; then
    log "Menggunakan git private authentication."
    GIT_HOST_PATH="$(echo "${GIT_ADDRESS}" | sed -E 's#https?://##')"
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@${GIT_HOST_PATH}"
fi

if [ "$(ls -A /mnt/server 2>/dev/null)" ]; then
    log "Folder tidak kosong. Mengecek repository lama."
    if [ -d .git ]; then
        ORIGIN="$(git config --get remote.origin.url 2>/dev/null || true)"
        if [ -n "${ORIGIN}" ]; then
            log "Repository ditemukan. Menarik update branch ${BRANCH:-default}."
            git fetch --all || true
            if [ -n "${BRANCH}" ]; then
                git checkout "${BRANCH}" || true
                git pull origin "${BRANCH}" || true
            else
                git pull || true
            fi
        fi
    else
        warn "Folder sudah ada isi dan bukan git repo. Clone dilewati agar data tidak hilang."
    fi
else
    log "Cloning repository: ${GIT_ADDRESS}"
    if [ -n "${BRANCH}" ]; then
        git clone --single-branch --branch "${BRANCH}" "${GIT_ADDRESS}" . || warn "Git clone gagal, lanjut terminal-only."
    else
        git clone "${GIT_ADDRESS}" . || warn "Git clone gagal, lanjut terminal-only."
    fi
fi

if [ "${AUTO_INSTALL_ON_START}" = "true" ] || [ "${AUTO_INSTALL_ON_START}" = "1" ]; then
    log "AUTO_INSTALL_ON_START aktif saat runtime. Dependency akan dicek ulang ketika server start."
fi

if [ -f package.json ]; then
    log "package.json terdeteksi. Install dependency Node."
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
        pnpm install --prod || npm install --omit=dev || true
    elif [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
        yarn install --production || npm install --omit=dev || true
    elif [ -f bun.lockb ] && command -v bun >/dev/null 2>&1; then
        bun install --production || npm install --omit=dev || true
    else
        npm install --omit=dev || npm install --production || true
    fi
fi

if [ -f requirements.txt ]; then
    log "requirements.txt terdeteksi. Install dependency Python."
    python3 -m pip install --break-system-packages -r requirements.txt || true
fi

if [ -f go.mod ]; then
    log "go.mod terdeteksi. Download dependency Go."
    go mod download || true
fi

if [ -f composer.json ]; then
    log "composer.json terdeteksi. Install dependency PHP."
    composer install --no-dev --no-interaction || composer install --no-interaction || true
fi

echo "================================================"
echo -e "${GREEN}        AKA MULTI TERMINAL READY${NC}"
echo "================================================"
echo "Startup bisa pakai: bash, auto, node index.js, npm start, python3 main.py, php -S, atau pm2-runtime."
echo "Cloudflare Tunnel bisa diaktifkan via ENABLE_CF_TUNNEL + CF_TOKEN atau CF_URL."
echo "================================================"
exit 0
