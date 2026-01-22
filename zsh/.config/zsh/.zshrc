# ----------------------------------------------
#
# ########  ######  ##     ## ########   ###### 
#      ##  ##    ## ##     ## ##     ## ##    ##
#     ##   ##       ##     ## ##     ## ##      
#    ##     ######  ######### ########  ##      
#   ##           ## ##     ## ##   ##   ##      
#  ##      ##    ## ##     ## ##    ##  ##    ##
# ########  ######  ##     ## ##     ##  ###### 
#
# ----------------------------------------------

# Load user functions
fpath=( "$XDG_DATA_HOME/zsh/functions" $fpath )
autoload -Uz install-zsh-plugins update-zsh-plugins

# Load completions
autoload -Uz compinit && compinit -i

# Load utils
source "$XDG_CONFIG_HOME/zsh/utils.zsh"

# Load plugins
source "${XDG_CONFIG_HOME}/zsh/plugins.zsh"

# Load custom prompt
source "${XDG_CONFIG_HOME}/zsh/prompt.zsh"

# Load custom cursor styling
source "$XDG_CONFIG_HOME/zsh/vimode.zsh"

# Load history
source "$XDG_CONFIG_HOME/zsh/history.zsh"

# Shell integrations
_have fzf && source <(fzf --zsh)

# Launch tmux
if _have tmux && ! _tty1 && ! _ssh_login && [[ -z $TMUX ]] && [[ -z $RAW_TERM ]]; then
    tmux new-session -A -s main
fi

[[ $(pgrep -cx "$TERMINAL") -eq 2 ]] && _have fastfetch && fastfetch
