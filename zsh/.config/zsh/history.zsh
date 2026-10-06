HISTSIZE=100000
HISTFILE="${XDG_CACHE_HOME}/zsh/history"
SAVEHIST=$HISTSIZE

setopt APPEND_HISTORY        # append to history file (Default)
setopt SHARE_HISTORY         # Share history between all sessions (also writes each command right away).
setopt EXTENDED_HISTORY      # Write the history file in the ':start:elapsed;command' format.
setopt HIST_IGNORE_ALL_DUPS  # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_SPACE     # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS     # Do not write a duplicate event to the history file
setopt HIST_FIND_NO_DUPS     # Do not show duplicates when navigating history
setopt HIST_VERIFY           # Do not execute immediately upon history expansion
setopt HIST_NO_STORE         # Do not store the history (fc -l) command itself
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from each command line being added to the history

