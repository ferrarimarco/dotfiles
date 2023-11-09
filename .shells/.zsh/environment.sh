#!/usr/bin/env zsh

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/environment.sh

# Make some commands not show up in history
export HISTORY_IGNORE="" # ZSH

# Set ZSH cache directory
export ZSH_CACHE_DIR="${USER_CACHE_DIRECTORY}/zsh"

# Don't run the ZSH theme configuration wizard
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export ZSH_THEME_CONFIGURATION_PATH="$HOME"/.shells/.zsh/.p10k.zsh
