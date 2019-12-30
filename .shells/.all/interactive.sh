#!/usr/bin/env sh

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
