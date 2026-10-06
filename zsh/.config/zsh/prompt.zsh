#!/bin/zsh

# Encapsulate in an IIFE to keep the namespace clean
() {
    # 1. Load Modules
    autoload -Uz add-zsh-hook add-zle-hook-widget vcs_info

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
    typeset -g _PROMPT_SHORT=""

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
        [[ -n $SSH_CONNECTION ]] && ssh_info="%F{magenta}%n@%M%f "

        # Get Distrobox Info
        local distro_info=$(_get_distrobox_info)

        # Assemble PROMPT
        PROMPT=$'\n'"${distro_info}${ssh_info}%F{${path_color}}%~%f ${vcs_info_msg_0_}"$'\n'"%F{${sym_col}}❯%f "

        # One-line version left on screen once the command is accepted (transient prompt)
        local user_sym="green"
        [[ $UID -eq 0 ]] && user_sym="208"
        _PROMPT_SHORT=$'\n'"${distro_info}${ssh_info}%F{${path_color}}%~%f %F{${user_sym}}❯%f "

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
    }

    # Transient prompt: when a line is accepted, redraw it with the one-line prompt. ZLE knows the
    # height of the prompt and of the command, so multi-line commands are redrawn correctly
    _prompt_transient() {
        PROMPT=$_PROMPT_SHORT
        RPROMPT=""
        zle reset-prompt
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
    add-zle-hook-widget line-finish _prompt_transient

    print -n "\e[5 q" # Start with beam cursor
}
