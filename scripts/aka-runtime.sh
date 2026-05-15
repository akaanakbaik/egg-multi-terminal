AKA_HOME="${HOME:-/home/container}"
AKA_PATH="${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
export HOME="$AKA_HOME"
export NVM_DIR="${NVM_DIR:-/usr/local/nvm}"
export PATH="$HOME/.local/bin:/opt/pytools/bin:/usr/local/bun/bin:/usr/local/bin:$AKA_PATH"
export TERM="${TERM:-xterm-256color}"
export PIP_BREAK_SYSTEM_PACKAGES="${PIP_BREAK_SYSTEM_PACKAGES:-1}"

aka_is_interactive() {
  case "${-:-}" in
    *i*) return 0 ;;
    *) [ -n "${PS1-}" ] && return 0 || return 1 ;;
  esac
}

aka_source_nvm() {
  if [ -s "${NVM_DIR}/nvm.sh" ]; then
    if [ -n "${BASH_VERSION-}" ] || [ -n "${ZSH_VERSION-}" ]; then
      . "${NVM_DIR}/nvm.sh" >/dev/null 2>&1 || true
    fi
  fi
}

aka_source_nvm

nodeuse() {
  version="${1:-}"
  if [ -z "$version" ]; then
    echo "Usage: nodeuse <18|20|22|node>"
    return 1
  fi
  if [ -s "${NVM_DIR}/nvm.sh" ] && { [ -n "${BASH_VERSION-}" ] || [ -n "${ZSH_VERSION-}" ]; }; then
    . "${NVM_DIR}/nvm.sh" >/dev/null 2>&1 || true
    nvm use "$version"
  else
    echo "nvm tidak tersedia untuk shell ini"
    return 1
  fi
}

rootsh() {
  if command -v sudo >/dev/null 2>&1; then
    sudo -E bash -l
  elif command -v su >/dev/null 2>&1; then
    su -
  else
    echo "sudo/su tidak tersedia"
    return 1
  fi
}

if aka_is_interactive; then
  alias n18='nodeuse 18'
  alias n20='nodeuse 20'
  alias n22='nodeuse 22'
  alias nlatest='nodeuse node'
  alias cls='clear'
  alias ll='ls -alF'
  alias ports='ss -tulpn'
  alias myip='curl -4s ifconfig.me || true'
  alias helpaka='aka-help'
  alias versions='aka-info'
  alias dash='aka-info'
  alias root='rootsh'

  if [ "$(id -u 2>/dev/null || echo 999)" = "0" ]; then
    PS1='\[\033[1;31m\]root\[\033[0m\]@\[\033[1;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]# '
  else
    PS1='\[\033[1;36m\]container\[\033[0m\]@\[\033[1;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]$ '
  fi
  export PS1
fi

unset AKA_HOME AKA_PATH
