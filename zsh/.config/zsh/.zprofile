# Load utils
source "$XDG_CONFIG_HOME/zsh/utils.zsh"

typeset -U path
path=(~/.local/bin $path)
export PATH

_have vim && export EDITOR=vim
_have nvim && export EDITOR=nvim
export VISUAL=$EDITOR
export PAGER=less
export TERMINAL=foot
export BROWSER=brave

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
