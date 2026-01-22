#!/bin/zsh

typeset -g EXIT_STATUS=0
typeset -g PROMPT_CMD_TEXT
NL=$'\n'

function get_status() {
    if [[ $EXIT_STATUS -eq 0 ]]; then
        if [[ $UID -eq 0 ]]; then
            echo '%F{orange}❯%f'
        else
            echo '%F{green}❯%f'
        fi
    else
        echo '%F{red}❯%f'
    fi
}

function capture_exit_status() {
    EXIT_STATUS=$?
}

function capture_command_text() {
    PROMPT_CMD_TEXT=$1
}

function transient_preexec() {
    if [[ "$TERM" != "dumb" ]]; then
        local status_color=$(get_status)
        local last_prompt="${status_color} ${PROMPT_CMD_TEXT}"
        
        echo -ne "\033[1A\033[K"
        echo -ne "\033[1A\033[K"
        print -P "${last_prompt}"
    fi
}

function custom_prompt() {
    local login=""
    local cwd=""
    local exit_status="$(get_status)"

    if [[ $SSH_CONNECTION ]]; then
        login='%F{purple}%n@%M%f '
    fi

    if [[ $UID -eq 0 ]]; then
        cwd='%F{red}%~%f' 
    else
        cwd='%F{blue}%~%f' 
    fi

    PROMPT=$NL"$login$cwd "$vcs_info_msg_0_$NL"$exit_status "
}

autoload -Uz capture_exit_status custom_prompt transient_preexec capture_command_text
autoload -Uz add-zsh-hook
autoload -Uz vcs_info

precmd_functions=( capture_exit_status $precmd_functions )
precmd_functions+=( vcs_info )
precmd_functions+=( custom_prompt )

add-zsh-hook preexec capture_command_text
add-zsh-hook preexec transient_preexec

zstyle ':vcs_info:git:*' formats '%F{yellow}%b%f'
