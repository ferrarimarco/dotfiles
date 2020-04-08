#!/usr/bin/env zsh

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/environment.sh

# Make some commands not show up in history
export HISTORY_IGNORE="" # ZSH

# Don't run the ZSH theme configuration wizard
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export ZSH_THEME_CONFIGURATION_PATH="$HOME"/.shells/.zsh/.p10k.zsh
