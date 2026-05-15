#!/usr/bin/env bash
set -Eeuo pipefail

source /etc/profile.d/aka-runtime.sh || true

mkdir -p /home/container
cd /home/container

if [[ "${AKA_SHOW_INFO:-1}" == "1" ]]; then
  aka-info || true
fi

STARTUP_COMMAND="${STARTUP_CMD:-bash}"

if [[ "$#" -gt 0 && "$1" != "bash" ]]; then
  exec "$@"
fi

case "${STARTUP_COMMAND}" in
  ""|"bash"|"/bin/bash"|"bash -i"|"/bin/bash -i")
    exec /bin/bash -i
    ;;
  *)
    echo -e "\033[36mMenjalankan STARTUP_CMD:\033[0m ${STARTUP_COMMAND}"
    exec /bin/bash -lc "${STARTUP_COMMAND}"
    ;;
esac
