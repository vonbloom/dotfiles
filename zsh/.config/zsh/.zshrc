# ----------------------------------------------
#
# ########  ######  ##     ## ########   ######
#      ##  ##    ## ##     ## ##     ## ##    ##
#     ##   ##       ##     ## ##     ## ##
#    ##     ######  ######### ########  ##
#   ##           ## ##     ## ##   ##   ##
#  ##      ##    ## ##     ## ##    ##  ##    ##
# ########  ######  ##     ## ##     ##  #####€
#
# ----------------------------------------------

# Load user functions
fpath=( "$ZDOTDIR/zsh/functions" $fpath )
autoload -Uz install-zsh-plugins source-zsh-plugins update-zsh-plugins

# Load utils
source "$ZDOTDIR/utils.zsh"

# Load history
source "$ZDOTDIR/history.zsh"

# Load prompt
source "$ZDOTDIR/prompt.zsh"

# Load aliases
emulate bash -c "source $DOTDIR/alias.bash"

# Load completions
autoload -Uz compinit && compinit -i

# Load plugins
source "$ZDOTDIR/zsh/plugins.zsh"

# Shell integrations
_have fzf && source <(fzf --zsh)

# Launch tmux
if _have tmux && ! _tty1 && ! _ssh_login && [[ -z $TMUX ]] && [[ -z $RAW_TERM ]]; then
    tmux new-session -A -s main
fi

# [[ $(pgrep -cx "$TERMINAL") -eq 2 ]] && _have fastfetch && fastfetch
