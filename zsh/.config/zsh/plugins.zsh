typeset -a zsh_plugins=(
    "Aloxaf/fzf-tab"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
)

local base_dir="$XDG_DATA_HOME/zsh/plugins"

[[ -d $base_dir ]] || mkdir -p $base_dir

install-zsh-plugins

zcompile $base_dir/**/*.zsh 2>/dev/null

source-zsh-plugins

unset plugin base_dir
