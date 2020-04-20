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
export LANGUAGE=$LANG
export LC_ALL=$LANG

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING='UTF-8'

###############################################################################
# Path                                                                        #
###############################################################################

# update path
export PATH=/usr/local/bin:${PATH}:/sbin
export PATH=$HOME/bin:$PATH

# ZSH related stuff that we might need during setup
export ZSH_PLUGINS_DIR="$HOME"/.shells/.zsh/plugins
export ZSH_THEMES_DIR="$HOME"/.shells/.zsh/themes
export ZSH_THEME_PATH="$ZSH_THEMES_DIR"/powerlevel10k/powerlevel10k.zsh-theme

os_name="$(uname -s)"
if [ "${os_name#*"Darwin"}" != "$os_name" ]; then

    # Might be needed to install Homebrew, so exporting in any case
    export HOMEBREW_REPOSITORY=/usr/local/Homebrew

    # setup homebrew environment
    if ! command -v brew >/dev/null 2>&1; then
        # brew is not yet in the path because it was (likely) installed manually by setup-dotfiles.sh
        # So falling back to a known location.
        HOMEBREW_PATH=/usr/local/brew
    else
        HOMEBREW_PATH="$(brew --prefix)"
    fi

    if [ -d "${HOMEBREW_PATH}" ]; then
        DEFAULT_SHELL="$HOMEBREW_PATH/bin/zsh"

        export HOMEBREW_PATH
        export PATH="${HOMEBREW_PATH}"/bin:"${PATH}"
        export PATH="${HOMEBREW_PATH}"/sbin:"${PATH}"
        export LD_LIBRARY_PATH="${HOMEBREW_PATH}"/lib:"${LD_LIBRARY_PATH}"
        export MANPATH="${HOMEBREW_PATH}"/share/man:"${MANPATH}"
        export HOMEBREW_NO_ANALYTICS=1

        ZSH_SITE_FUNCTIONS_PATH="${HOMEBREW_PATH}"/share/zsh/site-functions
        ZSH_SYNTAX_HIGHLIGHTING_PATH="${HOMEBREW_PATH}"/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_COMPLETIONS_PATH="${HOMEBREW_PATH}"/share/zsh-completions

        # On macOS, we install zsh-autosuggestions from brew
        ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH="${HOMEBREW_PATH}"/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

    # add vs code bins to path
    VS_CODE_BIN_DIRECTORY_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/"

elif test "${os_name#*"Linux"}" != "$os_name"; then
    if command -v zsh >/dev/null 2>&1; then
        DEFAULT_SHELL="$(command -v zsh)"
    elif command -v bash >/dev/null 2>&1; then
        DEFAULT_SHELL="$(command -v bash)"
    fi

    GOROOT="${HOME}/bin/go"

    RBENV_DIRECTORY_PATH="${HOME}/.rbenv"

    export RBENV_DIRECTORY_PATH
    export PATH="${RBENV_DIRECTORY_PATH}/bin:${PATH}"

    ZSH_SITE_FUNCTIONS_PATH=/usr/local/share/zsh/site-functions
    ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH="${ZSH_PLUGINS_DIR}"/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_COMPLETIONS_PATH="${ZSH_PLUGINS_DIR}"/zsh-completions/src
    ZSH_SYNTAX_HIGHLIGHTING_PATH=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

fi
unset os_name

[ -d "${VS_CODE_BIN_DIRECTORY_PATH}" ] && export PATH="${VS_CODE_BIN_DIRECTORY_PATH}:${PATH}"
unset VS_CODE_BIN_DIRECTORY_PATH

# ZSH related stuff that we might need during setup
export ZSH_SITE_FUNCTIONS_PATH
export ZSH_SYNTAX_HIGHLIGHTING_PATH
export ZSH_COMPLETIONS_PATH
export ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH

# Export default shell
export DEFAULT_SHELL

# Set up Go paths
export GOROOT
GO111MODULE=on
export GO111MODULE
GOPATH="${HOME}/.go"
export GOPATH
export PATH="${GOPATH}/bin:${GOROOT}/bin:${PATH}"
