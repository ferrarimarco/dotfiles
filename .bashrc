#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	*) return;;
esac

for file in "${HOME}"/.{path,bash_prompt,aliases,functions,extra,exports}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		. "$file"
	fi
done
unset file

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

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

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null
done

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

for file in "${HOME}"/.{init,motd}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		. "$file"
	fi
done
unset file
