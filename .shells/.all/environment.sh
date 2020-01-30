#!/usr/bin/env sh

# Set ENV so that if you use a shell as your login shell,
# and then start "sh" as a non-login interactive shell the startup scripts will
# correctly run.
export ENV="$HOME"/.shells/.all/interactive.sh

###############################################################################
# Path                                                                        #
###############################################################################

# go path
GOPATH="${HOME}/.go"
if [ -d "${GOPATH}" ]; then
    export GOPATH
    export PATH="/usr/local/go/bin:${GOPATH}/bin:${PATH}"
    export CDPATH=${CDPATH}:${GOPATH}/src/github.com:${GOPATH}/src/golang.org:${GOPATH}/src
else
    unset GOPATH
fi

# ZSH related stuff
export ZSH_THEMES_DIR="$HOME"/.shells/.zsh/themes

# update path
export PATH=/usr/local/bin:${PATH}:/sbin
export PATH=$HOME/bin:$PATH

# setup homebrew environment
HOMEBREW_PATH=/usr/local/brew
if [ -d "${HOMEBREW_PATH}" ]; then
    export HOMEBREW_REPOSITORY=/usr/local/Homebrew
    export HOMEBREW_PATH
    export PATH="${HOMEBREW_PATH}"/bin:"${PATH}"
    export PATH="${HOMEBREW_PATH}"/sbin:"${PATH}"
    export LD_LIBRARY_PATH="${HOMEBREW_PATH}"/lib:"${LD_LIBRARY_PATH}"
    export MANPATH="${HOMEBREW_PATH}"/share/man:"${MANPATH}"
    export HOMEBREW_NO_ANALYTICS=1

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

# add vs code bins to path
VS_CODE_PATH_MACOS="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/"
if [ -d "${VS_CODE_PATH_MACOS}" ]; then
    export PATH="${VS_CODE_PATH_MACOS}:${PATH}"
else
    unset VS_CODE_PATH_MACOS
fi
