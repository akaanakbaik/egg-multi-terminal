export NVM_DIR=/usr/local/nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi

export PATH="$HOME/.local/bin:/opt/pytools/bin:/usr/local/bun/bin:/usr/local/bin:$PATH"
export TERM="${TERM:-xterm-256color}"
export PIP_BREAK_SYSTEM_PACKAGES=1

nodeuse() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use "$1"
  else
    echo "nvm tidak ditemukan"
    return 1
  fi
}

rootsh() {
  if command -v sudo >/dev/null 2>&1; then
    sudo -E bash -l
  else
    su -
  fi
}

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

if [ -n "$PS1" ]; then
  if [ "$(id -u 2>/dev/null)" = "0" ]; then
    PS1='\[\033[1;31m\]root\[\033[0m\]@\[\033[1;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]# '
  else
    PS1='\[\033[1;36m\]container\[\033[0m\]@\[\033[1;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]$ '
  fi
fi
