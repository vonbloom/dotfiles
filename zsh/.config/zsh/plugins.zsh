local base_dir="$XDG_DATA_HOME/zsh/plugins"

[[ -d $base_dir ]] || mkdir -p $base_dir

local -a plugins=(
    "Aloxaf/fzf-tab"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
)

install_plugins "${plugins[@]}"

zcompile $base_dir/**/*.zsh 2>/dev/null

# Load zsh-completions first
source $base_dir/zsh-completions/zsh-completions.plugin.zsh

autoload -Uz compinit && compinit -i

# Source all plugins but zsh-completions
for plugin in "${(@)plugins:#zsh-users/zsh-completions}"; do
    name="${plugin##*/}"
    local target="${base_dir}/${name}/${name}.plugin.zsh"
    echo "Sourcing $target"
    [[ -f $target ]] && source $target
done
