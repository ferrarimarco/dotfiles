#!/usr/bin/env sh

# when leaving the console clear the screen to increase privacy
# shellcheck disable=SC2039  # Ignoring this so this script can be shell-agnostic
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
    [ -x /usr/bin/clear ] && /usr/bin/clear
fi
