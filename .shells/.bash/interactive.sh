#!/usr/bin/env bash

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/interactive.sh

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
    shopt -s "$option" 2>/dev/null
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
if command -v brew &>/dev/null; then
    BREW_PREFIX="$(brew --prefix)"

    BASH_COMPLETION_PATH="$BREW_PREFIX"/etc/profile.d/bash_completion.sh
    if [ -f "$BASH_COMPLETION_PATH" ]; then
        export BASH_COMPLETION_COMPAT_DIR="$BREW_PREFIX"/etc/bash_completion.d
        # shellcheck source=/dev/null
        . "$BASH_COMPLETION_PATH"
    fi

    BASH_COMPLETION_PATH="$BREW_PREFIX"/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
    # Enable shell command completion for gcloud SDK
    if [ -f "$BASH_COMPLETION_PATH" ]; then
        # shellcheck source=/dev/null
        . "$BASH_COMPLETION_PATH"
    fi

    unset BASH_COMPLETION_PATH
    unset BREW_PREFIX
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &>/dev/null; then
    complete -o default -o nospace -F _git g
fi

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
if command -v defaults &>/dev/null; then
    complete -W "NSGlobalDomain" defaults
fi

# shellcheck source=/dev/null
command -v kubectl >/dev/null 2>&1 && . <(kubectl completion bash)

# shellcheck source=/dev/null
command -v rbenv >/dev/null 2>&1 && . "${RBENV_DIRECTORY_PATH}"/.rbenv/completions/rbenv.bash

###############################################################################
# Bash prompt                                                                 #
###############################################################################

# Shell prompt based on the Solarized Dark theme.
# Screenshot: http://i.imgur.com/EkEtphC.png
# Heavily inspired by @necolas’s prompt: https://github.com/necolas/dotfiles
# iTerm → Profiles → Text → use 13pt Monaco with 1.1 vertical spacing.

prompt_git() {
    local s=''
    local branchName=''

    # Check if the current directory is in a Git repository.
    git rev-parse --is-inside-work-tree &>/dev/null || return

    # Check for what branch we’re on.
    # Get the short symbolic ref. If HEAD isn’t a symbolic ref, get a
    # tracking remote branch or tag. Otherwise, get the
    # short SHA for the latest commit, or give up.
    branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null ||
        git describe --all --exact-match HEAD 2>/dev/null ||
        git rev-parse --short HEAD 2>/dev/null ||
        echo '(unknown)')"

    # Early exit for Chromium & Blink repo, as the dirty check takes too long.
    # Thanks, @paulirish!
    # https://github.com/paulirish/dotfiles/blob/dd33151f/.bash_prompt#L110-L123
    repoUrl="$(git config --get remote.origin.url)"
    if grep -q 'chromium/src.git' <<<"${repoUrl}"; then
        s+='*'
    else
        # Check for uncommitted changes in the index.
        if ! git diff --quiet --ignore-submodules --cached; then
            s+='+'
        fi
        # Check for unstaged changes.
        if ! git diff-files --quiet --ignore-submodules --; then
            s+='!'
        fi
        # Check for untracked files.
        if [ -n "$(git ls-files --others --exclude-standard)" ]; then
            s+='?'
        fi
        # Check for stashed files.
        if git rev-parse --verify refs/stash &>/dev/null; then
            s+='$'
        fi
    fi

    [ -n "${s}" ] && s=" [${s}]"

    echo -e "${1}${branchName}${2}${s}"
}

if tput setaf 1 &>/dev/null; then
    tput sgr0 # reset colors
    bold=$(tput bold)
    reset=$(tput sgr0)
    # Solarized colors, taken from http://git.io/solarized-colors.
    black=$(tput setaf 0)
    blue=$(tput setaf 33)
    cyan=$(tput setaf 37)
    green=$(tput setaf 64)
    orange=$(tput setaf 166)
    purple=$(tput setaf 125)
    red=$(tput setaf 124)
    violet=$(tput setaf 61)
    white=$(tput setaf 15)
    yellow=$(tput setaf 136)
else
    bold=''
    reset="\e[0m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    black="\e[1;30m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    blue="\e[1;34m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    cyan="\e[1;36m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    green="\e[1;32m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    orange="\e[1;33m"
    # Unused variables left for future use
    # shellcheck disable=SC2034
    purple="\e[1;35m"
    red="\e[1;31m"
    violet="\e[1;35m"
    white="\e[1;37m"
    yellow="\e[1;33m"
fi

# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
    userStyle="${red}"
else
    userStyle="${orange}"
fi

# Highlight the hostname when connected via SSH.
if [[ "${SSH_TTY}" ]]; then
    hostStyle="${bold}${red}"
else
    hostStyle="${yellow}"
fi

# Set the terminal title and prompt.
PS1="\[\033]0;\W\007\]"   # working directory base name
PS1+="\[${bold}\]\n"      # newline
PS1+="\[${userStyle}\]\u" # username
PS1+="\[${white}\] at "
PS1+="\[${hostStyle}\]$(hostname -f)" # host
PS1+="\[${white}\] in "
PS1+="\[${green}\]\w"                                                   # working directory full path
PS1+="\$(prompt_git \"\[${white}\] on \[${violet}\]\" \"\[${blue}\]\")" # Git repository details
PS1+="\n"
PS1+="\[${white}\]\$ \[${reset}\]" # `$` (and reset color)
export PS1

PS2="\[${yellow}\]→ \[${reset}\]"
export PS2
