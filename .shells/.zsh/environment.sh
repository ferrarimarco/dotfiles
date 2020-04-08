#!/usr/bin/env zsh

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/environment.sh

# Make some commands not show up in history
export HISTORY_IGNORE="" # ZSH

# Define zsh-autosuggestions path for non-macOS systems
ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH="${ZSH_PLUGINS_DIR}"/zsh-autosuggestions/zsh-autosuggestions.zsh

if command -v brew &> /dev/null; then
    BREW_PREFIX="$(brew --prefix)"

    ZSH_SYNTAX_HIGHLIGHTING_PATH="${BREW_PREFIX}"/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_COMPLETIONS_PATH="${BREW_PREFIX}"/share/zsh-completions

    # On macOS, we install zsh-autosuggestions from brew
    ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH="${BREW_PREFIX}"/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    unset BREW_PREFIX
fi

export ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH

export ZSH_THEME_PATH="$ZSH_THEMES_DIR"/powerlevel10k/powerlevel10k.zsh-theme

# Don't run the ZSH theme configuration wizard
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export ZSH_THEME_CONFIGURATION_PATH="$HOME"/.shells/.zsh/.p10k.zsh
