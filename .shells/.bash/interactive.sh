#!/usr/bin/env bash

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/interactive.sh

# shellcheck source=/dev/null
. "$HOME"/.bash_prompt

###############################################################################
# Bash options                                                                #
###############################################################################

# Enable some Bash features when possible:
# * If `autocd` is set, a command name that is the name of a directory is executed
#   as if it were the argument to the cd command.
# * If `cdspell` is set, bash autocorrects typos in path names when using `cd`
# * If `checkwinsize` is set, bash checks the window size after each command and, if necessary,
#   updates the values of LINES and COLUMNS.
for option in autocd cdspell checkwinsize; do
	shopt -s "$option" 2> /dev/null
done

###############################################################################
# Completion                                                                  #
###############################################################################

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
	if [[ -f /usr/share/bash-completion/bash_completion ]]; then
		# shellcheck source=/dev/null
		. /usr/share/bash-completion/bash_completion
	elif [[ -f /etc/bash_completion ]]; then
		# shellcheck source=/dev/null
		. /etc/bash_completion
	elif [[ -f /usr/local/etc/bash_completion ]]; then
		# shellcheck source=/dev/null
		. /usr/local/etc/bash_completion
	fi
fi

# Add tab completion for many Bash commands on macOS
if command -v brew &> /dev/null; then
	BREW_PREFIX="$(brew --prefix)"

	BASH_COMPLETION_PATH="$BREW_PREFIX"/etc/profile.d/bash_completion.sh
	if [ -f "$BASH_COMPLETION_PATH" ]; then
		export BASH_COMPLETION_COMPAT_DIR="$BREW_PREFIX"/etc/bash_completion.d
		# shellcheck source=/dev/null
		. "$BASH_COMPLETION_PATH";
	fi

	BASH_COMPLETION_PATH="$BREW_PREFIX"/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
	# Enable shell command completion for gcloud SDK
	if [ -f "$BASH_COMPLETION_PATH" ]; then
		# shellcheck source=/dev/null
		. "$BASH_COMPLETION_PATH";
	fi

	unset BASH_COMPLETION_PATH
	unset BREW_PREFIX
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
if command -v defaults &> /dev/null; then
	complete -W "NSGlobalDomain" defaults;
fi

# source kubectl bash completion
if command -v kubectl &> /dev/null; then
	# shellcheck source=/dev/null
	. <(kubectl completion bash)
fi
