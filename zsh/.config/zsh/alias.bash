#!/bin/bash

alias ls='ls -hN --color=auto --group-directories-first'
alias la='ls -la'
alias ll='ls -l'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias clear='printf "\e[H\e[2J"'
alias c='clear'

_have vim && alias v=vim
_have nvim && alias v=nvim

alias gs='git status'
alias gl='git log'
alias gar='git add --all && git reset --hard'
alias gfa='git fetch --all --prune'

alias fcd='cd $(find -d | fzf -e --exact)'
alias open='xdg-open'

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
        LESS_TERMCAP_me=$'\e[0m' \
        LESS_TERMCAP_se=$'\e[0m' \
        LESS_TERMCAP_so=$'\e[01;44;33m' \
        LESS_TERMCAP_ue=$'\e[0m' \
        LESS_TERMCAP_us=$'\e[01;32m' \
        command man "$@"
}
