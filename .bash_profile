#!/usr/bin/env bash

# ~/.bash_profile: executed by bash(1) for login shells.

# shellcheck source=/dev/null
. "$HOME"/.shells/.bash/login.sh

# Run this if is an interactive shell.
if [ "$PS1" ]; then
    # shellcheck source=/dev/null
    . "$HOME"/.shells/.bash/interactive.sh
fi
