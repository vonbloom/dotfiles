[[ -n $_LOADED ]] && return
readonly _LOADED=1
_have() {
    command -v "$1" &>/dev/null
}

_source_if_exists() {
    test -r "$1" && source "$1"
}

_ssh_login() {
    [[ -n $SSH_TTY ]]
}

_tty1() {
    [[ $(tty) == "/dev/tty1" ]]
}

_is_root() {
    [[ $UID -eq 0 ]]
}

_is_git() {
    [[ -d .git ]]
}

_is_dir() {
    [[ -d $1 ]]
}
