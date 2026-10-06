[[ -n $_ZSH_UTILS_LOADED ]] && return
readonly _ZSH_UTILS_LOADED=1

_have() {
    command -v "$1" &>/dev/null
}
