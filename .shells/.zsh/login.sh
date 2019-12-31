#!/usr/bin/env zsh

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/login.sh

###############################################################################
# Expansion and globbing                                                      #
###############################################################################

setopt GLOB_DOTS             # Do not require a leading ‘.’ in a filename to be matched explicitly. Example: Recursive globbing, e.g. `echo **/*.txt`
unsetopt CASE_GLOB           # Make globbing (filename generation) not sensitive to case
unsetopt NOMATCH             # Disable: If a pattern for filename generation has no matches, print an error, instead of leaving it unchanged in the argument list.

###############################################################################
# History                                                                     #
###############################################################################

[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"

setopt APPEND_HISTORY         # zsh sessions append their history list to the history file, rather than replace it.
setopt EXTENDED_HISTORY       # record timestamp of command in HISTFILE
setopt HIST_EXPIRE_DUPS_FIRST # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_DUPS       # ignore duplicated commands history list
setopt HIST_IGNORE_SPACE      # ignore commands that start with space
setopt HIST_VERIFY            # show command with history expansion to user before running it
setopt INC_APPEND_HISTORY     # add commands to HISTFILE in order of execution
setopt SHARE_HISTORY          # share command history data
