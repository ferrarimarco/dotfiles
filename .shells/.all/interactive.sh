#!/usr/bin/env sh

for file in "${HOME}"/.{path,aliases,functions,extra}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		. "$file"
	fi
done
unset file

# Initialize rbenv if available
if command -v rbenv &> /dev/null; then
	eval "$(rbenv init -)"
fi;

###############################################################################
# MOTD                                                                        #
###############################################################################
if command -v sw_vers &> /dev/null; then
	sw_vers
fi;

if command -v uname &> /dev/null; then
	uname -snrvm
fi;
