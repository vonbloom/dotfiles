#!/bin/zsh
[[ -z $WAYLAND_DISPLAY && $XDG_VTNR -eq 1 ]] && exec systemd-cat -t sway sway
