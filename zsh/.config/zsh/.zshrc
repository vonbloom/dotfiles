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
fpath=( "$XDG_DATA_HOME/zsh/functions" $fpath )
autoload -Uz install-zsh-plugins source-zsh-plugins update-zsh-plugins

# Load utils
source "$ZDOTDIR/utils.zsh"

# Load history
source "$ZDOTDIR/history.zsh"

# Load prompt
source "$ZDOTDIR/prompt.zsh"

# Load aliases
emulate bash -c "source $ZDOTDIR/alias.bash"

# Load completions (separate dump per environment: host and distroboxes have different fpaths)
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${CONTAINER_ID:-host}"
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}
autoload -Uz compinit && compinit -i -d "$_zcompdump"
unset _zcompdump

# Load plugins
source "$ZDOTDIR/plugins.zsh"

# Shell integrations
_have fzf && source <(fzf --zsh)

# [[ $(pgrep -cx "$TERMINAL") -eq 2 ]] && _have fastfetch && fastfetch
