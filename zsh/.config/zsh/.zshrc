autoload -Uz compinit && compinit

if [[ -n ${CONTAINER_ID:-} ]]; then
	# `CONTAINER_ID`is available in containers created by Distrobox.
	# See https://github.com/89luca89/distrobox/blob/7c0c1e5fcd3c065d43a52412d39654bca82afc28/distrobox-init#L2100
	# Style prompt to indicate shell instance running inside a container.
	# Also, show the container ID instead of the hostname.
	PS1="📦 %(?..[%F{136}%?%f] )%n%f@%F{35}$CONTAINER_ID%f %1~ %#> "
elif [[ ! $HOSTNAME == 'toolbox' ]]; then
	PS1='%(?..[%F{136}%?%f] )%n%f@%F{136}%m%f %1~ %#> '
else
	# Prompt style, when the hostname is set to toolbox it will load a custom promp style,
	# this is useful to quickly visually identify containerized shell instances
	PS1='⬢ %(?..[%F{136}%?%f] )%n%f@%F{35}%m%f %1~ %#> '
fi

# Zsh history location and settings
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# ctrl + left/right word forwards/backwards
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# shift + tab for reverse tab-completion
bindkey '^[[Z' reverse-menu-complete

# Show selection on tab completion
zstyle ':completion:*' menu select

# Custom chars which define beginning or end of words
WORDCHARS=${WORDCHARS/\/}

# Zsh autosuggestions and syntax highlighting plugins
[[ -f '/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' ]] &&
	source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f '/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' ]] &&
	source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Use colors for ls
alias ls='ls --color=auto'

export PATH="$HOME/.local/bin:$PATH"
