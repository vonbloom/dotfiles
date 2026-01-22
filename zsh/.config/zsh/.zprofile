_have vim && export EDITOR=vim
_have nvim && export EDITOR=nvim
export VISUAL=$EDITOR
export PAGER=less
export BROWSER=brave

export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
