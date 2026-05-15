export NVM_DIR=/usr/local/nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
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

if [ -n "$PS1" ]; then
  PS1='\[\033[1;36m\]aka\[\033[0m\]@\[\033[1;35m\]terminal\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]\$ '
fi
