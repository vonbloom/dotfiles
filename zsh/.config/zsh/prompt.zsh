#!/bin/zsh

# Encapsulate in an IIFE to keep the namespace clean
() {
    # 1. Load Modules
    autoload -Uz add-zsh-hook vcs_info

    # 2. Keybindings & Vi Mode Configuration
    bindkey -v
    export KEYTIMEOUT=1
    bindkey '^?' backward-delete-char
    bindkey '^[[3~' delete-char

    autoload -Uz edit-command-line
    zle -N edit-command-line
    bindkey -M vicmd 'v' edit-command-line

    # 3. Version Control System Setup
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%f'
    zstyle ':vcs_info:git:*' actionformats '%F{yellow}(%b|%a)%f'

    # 4. Global State
    typeset -g CMD_START_TIME=""

    # 5. Optimized Helper Functions
		_get_distrobox_info() {
        # Distrobox typically exports $CONTAINER_ID inside the container
        if [[ -n $CONTAINER_ID || -f /run/.containerenv ]]; then
            # Use CONTAINER_ID if available, otherwise fallback to "container"
            local name="${CONTAINER_ID:-container}"
            # local icon="" # Default container icon (Nerd Font)

            echo "%F{cyan}${name}%f "
        fi
    }

    # 6. Hook Functions
    _prompt_precmd() {
        local last_status=$?
        vcs_info

        # Dynamic User/Root Check
        local path_color="blue"
        local sym_col="green"
        [[ $last_status -ne 0 ]] && sym_col="red"

        # Dynamic SSH Check
        local ssh_info=""
        [[ -n $SSH_CONNECTION ]] && ssh_info="%F{purple}%n@%M%f "

        # Get Distrobox Info
        local distro_info=$(_get_distrobox_info)

        # Assemble PROMPT
        PROMPT=$'\n'"${distro_info}${ssh_info}%F{${path_color}}%~%f ${vcs_info_msg_0_}"$'\n'"%F{${sym_col}}❯%f "

        # Assemble RPROMPT (Timer)
        RPROMPT=""
        if [[ -n $CMD_START_TIME ]]; then
            local duration=$(( SECONDS - CMD_START_TIME ))
            [[ $duration -ge 3 ]] && RPROMPT="%F{yellow}${duration}s%f"
        fi

        CMD_START_TIME=""
    }

    _prompt_preexec() {
        CMD_START_TIME=$SECONDS

        if [[ "$TERM" != "dumb" ]]; then
            local trans_sym="%F{green}❯%f"
            [[ $UID -eq 0 ]] && trans_sym="%F{orange}❯%f"
            print -Pn "\e[1A\e[K${trans_sym} ${1}\n"
        fi
    }

    # 7. Cursor Shape Management
    _update_cursor() {
        case $KEYMAP in
            vicmd)      print -n "\e[1 q" ;;
            viins|main) print -n "\e[5 q" ;;
        esac
    }

    # 8. Registration
    zle -N zle-keymap-select _update_cursor
    zle -N zle-line-init _update_cursor

    add-zsh-hook preexec _prompt_preexec
    add-zsh-hook precmd _prompt_precmd

    print -n "\e[5 q" # Start with beam cursor
}
