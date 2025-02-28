# THIS FILE IS MANAGED BY PUPPET

# colorized tail
ctail() {
  tail "$@" | ccze -A -o nolookups
}
# colorized journalctl
cj() {
  journalctl -f "$@" | ccze -A -o nolookups
}

if [ $(command -v dircolors) ]; then
  eval "$(dircolors)"
fi

# workaround for broken systemd/kernel sync
alias reboot='sync; reboot'
alias poweroff='sync; poweroff'

export LS_OPTIONS='--color=auto -h'
export EDITOR='vim'

# colorize iostat
export S_COLORS=auto

# colorized PS1
export PS1='\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]'

alias ncdu='ncdu --color dark'
alias dmesg='dmesg -T --color'
alias r10k='r10k --color'
alias ip='ip -c'
alias grep='grep --color'
alias ls='ls $LS_OPTIONS'
alias ll='ls -l'
alias l='ls $LS_OPTIONS -lA'

if [ $TERM == "alacritty" ]; then export TERM=xterm-256color; fi
