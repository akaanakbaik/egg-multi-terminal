#!/bin/bash
set -Eeuo pipefail

LOG_FILE=/mnt/server/install.log
mkdir -p /mnt/server
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

BOLD='\033[1m'
DIM='\033[2m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'
TOTAL=9
STEP=0

bar() {
  local p="$1" w=24 f e out=""
  f=$((p*w/100)); e=$((w-f))
  for ((i=0;i<f;i++)); do out+="█"; done
  for ((i=0;i<e;i++)); do out+="░"; done
  printf "%s" "$out"
}

banner() {
  clear 2>/dev/null || true
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${MAGENTA}║${RESET} ${BOLD}${CYAN}AKA MULTI TERMINAL INSTALLER${RESET} ${DIM}for Pterodactyl${RESET}              ${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${YELLOW}Image${RESET}      ghcr.io/akaanakbaik/egg-multi-terminal:nightly"
  echo -e "${YELLOW}Workdir${RESET}    /mnt/server"
  echo -e "${YELLOW}Log file${RESET}   $LOG_FILE"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

step() {
  STEP=$((STEP+1))
  local p=$((STEP*100/TOTAL))
  echo -e "${BLUE}[${STEP}/${TOTAL}]${RESET} $1"
  echo -e "    ${GREEN}$(bar "$p")${RESET} ${p}%"
}

ok() { echo -e "    ${GREEN}✓${RESET} $1"; }
warn() { echo -e "    ${YELLOW}⚠${RESET} $1"; }

fail() {
  code=$?
  echo
  echo -e "${RED}╔════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${RED}║ INSTALLATION FAILED                                        ║${RESET}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${YELLOW}Exit code:${RESET} $code"
  echo -e "${YELLOW}Log file:${RESET} $LOG_FILE"
  echo -e "${CYAN}Last log:${RESET}"
  tail -80 "$LOG_FILE" || true
  exit "$code"
}
trap fail ERR

soft() { "$@" || warn "Gagal tapi dilanjutkan: $*"; }

banner

step "Preparing workspace"
cd /mnt/server
ok "Workspace ready"

step "Installing base installer packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl jq file unzip make gcc g++ python3 python3-pip ca-certificates
ok "Base packages ready"

step "Reading install variables"
echo -e "    ${YELLOW}USER_UPLOAD${RESET}=${USER_UPLOAD:-false}"
echo -e "    ${YELLOW}GIT_ADDRESS${RESET}=${GIT_ADDRESS:-empty}"
echo -e "    ${YELLOW}BRANCH${RESET}=${BRANCH:-default}"
echo -e "    ${YELLOW}AUTO_INSTALL_ON_START${RESET}=${AUTO_INSTALL_ON_START:-false}"
ok "Variables loaded"

step "Checking deployment mode"
GIT_MODE=skip
if [ "${USER_UPLOAD:-false}" = "true" ] || [ "${USER_UPLOAD:-false}" = "1" ]; then
  ok "Manual upload mode enabled"
elif [ -z "${GIT_ADDRESS:-}" ]; then
  ok "No git repository set. Terminal-only mode enabled"
else
  GIT_MODE=clone
  ok "Git deployment mode enabled"
fi

step "Syncing repository"
if [ "$GIT_MODE" = "clone" ]; then
  case "${GIT_ADDRESS}" in *.git) true ;; *) GIT_ADDRESS="${GIT_ADDRESS}.git" ;; esac
  if [ -n "${USERNAME:-}" ] && [ -n "${ACCESS_TOKEN:-}" ]; then
    warn "Private git authentication enabled"
    GIT_HOST_PATH="$(echo "${GIT_ADDRESS}" | sed -E 's#https?://##')"
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@${GIT_HOST_PATH}"
  fi
  if [ "$(ls -A /mnt/server 2>/dev/null)" ]; then
    if [ -d .git ]; then
      ok "Existing git repository found"
      soft git fetch --all
      if [ -n "${BRANCH:-}" ]; then soft git checkout "${BRANCH}"; soft git pull origin "${BRANCH}"; else soft git pull; fi
    else
      warn "Folder not empty and not a git repository. Clone skipped to protect files"
    fi
  else
    if [ -n "${BRANCH:-}" ]; then soft git clone --single-branch --branch "${BRANCH}" "${GIT_ADDRESS}" .; else soft git clone "${GIT_ADDRESS}" .; fi
  fi
else
  ok "Repository sync skipped"
fi

step "Detecting project type"
PROJECTS=()
[ -f package.json ] && PROJECTS+=("Node.js")
[ -f requirements.txt ] && PROJECTS+=("Python")
[ -f go.mod ] && PROJECTS+=("Go")
[ -f composer.json ] && PROJECTS+=("PHP")
[ -f Gemfile ] && PROJECTS+=("Ruby")
if [ "${#PROJECTS[@]}" -gt 0 ]; then echo -e "    ${GREEN}Detected:${RESET} ${PROJECTS[*]}"; else echo -e "    ${DIM}No dependency manifest detected. Terminal-only is okay.${RESET}"; fi
ok "Project scan complete"

step "Installing detected dependencies"
if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then soft pnpm install --prod;
  elif [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then soft yarn install --production;
  elif { [ -f bun.lockb ] || [ -f bun.lock ]; } && command -v bun >/dev/null 2>&1; then soft bun install --production;
  else soft npm install --omit=dev; fi
fi
[ -f requirements.txt ] && soft python3 -m pip install --break-system-packages -r requirements.txt
[ -f go.mod ] && soft go mod download
[ -f composer.json ] && soft composer install --no-dev --no-interaction
[ -f Gemfile ] && command -v bundle >/dev/null 2>&1 && soft bundle install
ok "Dependency phase complete"

step "Finalizing permissions and hints"
chmod -R u+rwX /mnt/server || true
cat > /mnt/server/.aka-terminal-hints <<'HINTS'
Aka Multi Terminal ready.
Useful commands:
- aka-info
- aka-help
- rootsh
- n18 / n20 / n22 / nlatest
- tail -f cloudflared.log
HINTS
ok "Hints written"

step "Building final dashboard"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}INSTALLATION COMPLETE${RESET}"
echo -e "${YELLOW}Startup examples:${RESET}"
echo "  bash"
echo "  auto"
echo "  node index.js"
echo "  npm start"
echo "  pm2-runtime start ecosystem.config.js"
echo "  python3 main.py"
echo "  php artisan serve --host=0.0.0.0 --port=\${SERVER_PORT}"
echo -e "${YELLOW}Cloudflare Tunnel:${RESET} ENABLE_CF_TUNNEL=true + CF_TOKEN or CF_URL"
echo -e "${YELLOW}Command shell:${RESET} container@<docker-id>:/home/container$"
echo -e "${YELLOW}Root shell:${RESET} ketik rootsh untuk root@<docker-id>:/home/container#"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}AKA_MULTI_TERMINAL_INSTALL_READY${RESET}"
exit 0
