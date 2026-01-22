#!/bin/zsh

# ----------------------------------------------
# ZSH VI MODE: Canvi de forma del cursor (ANSI)
# ----------------------------------------------

bindkey -v
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char

# Funció que s'executa quan el mapa de tecles de Zsh canvia
function zle-keymap-select() {
  case $KEYMAP in
    vicmd)
      # Mode Normal (vicmd): Cursor de BLOQUE (quadrat)
      # Codi ANSI: \e[1 q (o \e[2 q en alguns terminals)
      echo -ne '\e[1 q'
      ;;
    viins|main)
      # Mode Inserció (viins o main): Cursor de BARRA (vertical)
      # Codi ANSI: \e[5 q (o \e[6 q en alguns terminals)
      echo -ne '\e[5 q'
      ;;
  esac
}
# Enllaça la funció a l'esdeveniment de canvi de mapa de tecles
zle -N zle-keymap-select

# Funció que s'executa en iniciar una línia nova (per assegurar-se que comença en mode Inserció/Barra)
function zle-line-init() {
  # Assegura que el cursor comença en mode Barra/Inserció
  echo -ne '\e[5 q'
}
# Enllaça la funció a l'esdeveniment d'inici de línia
zle -N zle-line-init

# Assegura que el cursor és de barra quan s'inicia la terminal
echo -ne '\e[5 q'
