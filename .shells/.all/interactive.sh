#!/usr/bin/env sh

# shellcheck source=/dev/null
FILE="${HOME}"/.path && test -f "$FILE" && . "$FILE"

# shellcheck source=/dev/null
FILE="${HOME}"/.aliases && test -f "$FILE" && . "$FILE"

# shellcheck source=/dev/null
FILE="${HOME}"/.functions && test -f "$FILE" && . "$FILE"

# source docker aliases if docker is installed
if command -v docker > /dev/null 2>&1; then
	# shellcheck source=/dev/null
	FILE="${HOME}"/.dockerfunc && test -f "$FILE" && . "$FILE"
fi;

# shellcheck source=/dev/null
FILE="${HOME}"/.extra && test -f "$FILE" && . "$FILE"

unset FILE

# Initialize rbenv if available
if command -v rbenv > /dev/null 2>&1; then
	eval "$(rbenv init -)"
fi;

###############################################################################
# MOTD                                                                        #
###############################################################################
if command -v sw_vers > /dev/null 2>&1; then
	sw_vers
fi;

if command -v uname > /dev/null 2>&1; then
	uname -snrvm
fi;
