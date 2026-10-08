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

# gpg-agent asks for the passphrase (also of the SSH keys it holds) where the last interactive shell
# is: a dialog in a sway terminal, a prompt in the terminal itself over SSH (no display: pinentry-gtk
# falls back to curses). Without it an SSH session to this machine could not unlock the key, and
# ssh fell back to the keys in ~/.ssh and asked for theirs
export GPG_TTY=$TTY
(( $+commands[gpg-connect-agent] )) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

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

# fzf key bindings (Ctrl+R history, Ctrl+T files, Alt+C cd). Before the plugins: fzf also binds
# Tab to its own completion, and fzf-tab (loaded next) must take Tab over again
_have fzf && source <(fzf --zsh)

# Load plugins
source "$ZDOTDIR/plugins.zsh"
