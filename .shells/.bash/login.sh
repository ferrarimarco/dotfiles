#!/usr/bin/env bash

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/login.sh

###############################################################################
# Bash options                                                                #
###############################################################################

# Enable some Bash features when possible:
# * If `globstar` is set, the pattern "**" used in a pathname expansion context will
#   match all files and zero or more directories and subdirectories.
#   Example: Recursive globbing, e.g. `echo **/*.txt`
# * If `histappend` is set, Bash appends to the Bash history file, rather than overwriting it
# * If `nocaseglob` is set, Bash uses case-insensitive globbing in pathname expansion
for option in globstar histappend nocaseglob; do
	shopt -s "$option" 2> /dev/null
done
