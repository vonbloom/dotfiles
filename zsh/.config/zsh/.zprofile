#!/bin/zsh
[[ -z $WAYLAND_DISPLAY && $XDG_VTNR -eq 1 ]] && exec sway -d > ~/sway.log 2>&1
