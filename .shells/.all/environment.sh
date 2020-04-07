#!/usr/bin/env sh

# Set ENV so that if you use a shell as your login shell,
# and then start "sh" as a non-login interactive shell the startup scripts will
# correctly run.
export ENV="$HOME"/.shells/.all/interactive.sh

###############################################################################
# Shell                                                                       #
###############################################################################

# Set the default editor
export EDITOR=/usr/bin/nano
export TERMINAL="urxvt"
export VISUAL=$EDITOR

# Larger command history
export HISTSIZE=50000000
export HISTFILESIZE=$HISTSIZE
export SAVEHIST=$HISTSIZE

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth'

# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL=$LANG

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING='UTF-8'

###############################################################################
# Path                                                                        #
###############################################################################

# ZSH related stuff
export ZSH_PLUGINS_DIR="$HOME"/.shells/.zsh/plugins
export ZSH_THEMES_DIR="$HOME"/.shells/.zsh/themes

# update path
export PATH=/usr/local/bin:${PATH}:/sbin
export PATH=$HOME/bin:$PATH

os_name="$(uname -s)"
if test "${os_name#*"Darwin"}" != "$os_name"; then
    # setup homebrew environment
    HOMEBREW_PATH=/usr/local/brew
    if [ -d "${HOMEBREW_PATH}" ]; then
        DEFAULT_SHELL="$HOMEBREW_PATH/bin/zsh"
        export HOMEBREW_REPOSITORY=/usr/local/Homebrew
        export HOMEBREW_PATH
        export PATH="${HOMEBREW_PATH}"/bin:"${PATH}"
        export PATH="${HOMEBREW_PATH}"/sbin:"${PATH}"
        export LD_LIBRARY_PATH="${HOMEBREW_PATH}"/lib:"${LD_LIBRARY_PATH}"
        export MANPATH="${HOMEBREW_PATH}"/share/man:"${MANPATH}"
        export HOMEBREW_NO_ANALYTICS=1

        GOROOT="${HOMEBREW_PATH}/opt/go/libexec"

        # Uncomment the lines below if you want to use executables installed with Homebrew
        # instead of the macOS ones
        #export PATH="${HOMEBREW_PATH}"/opt/coreutils/libexec/gnubin:${PATH}
        #export MANPATH="${HOMEBREW_PATH}"/opt/coreutils/libexec/gnuman:${MANPATH}
        #export PATH="${HOMEBREW_PATH}"/opt/make/libexec/gnubin:${PATH}
        #export MANPATH="${HOMEBREW_PATH}"/opt/make/libexec/gnuman:${MANPATH}
        #export PATH="${HOMEBREW_PATH}"/opt/findutils/libexec/gnubin:${PATH}
        #export MANPATH="${HOMEBREW_PATH}"/opt/findutils/libexec/gnuman:${MANPATH}
    else
        unset HOMEBREW_PATH
    fi
elif test "${os_name#*"Linux"}" != "$os_name"; then
    DEFAULT_SHELL="$(command -v zsh)"
fi
unset os_name

# Export default shell
# Set a value for DEFAULT_SHELL for each OS
export DEFAULT_SHELL

# go path
GOPATH="${HOME}/.go"
if [ -d "${GOPATH}" ]; then
    export GOPATH
    export GOROOT
    export PATH="${GOPATH}/bin:${GOROOT}/bin:${PATH}"
else
    unset GOPATH
fi

# add vs code bins to path
VS_CODE_PATH_MACOS="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/"
if [ -d "${VS_CODE_PATH_MACOS}" ]; then
    export PATH="${VS_CODE_PATH_MACOS}:${PATH}"
else
    unset VS_CODE_PATH_MACOS
fi
