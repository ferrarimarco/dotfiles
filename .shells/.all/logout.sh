#!/usr/bin/env sh

# Leaving the console clear the screen to increase privacy
# Ignoring this so this script can be shell-agnostic

# shellcheck disable=SC2039
if [ "$SHLVL" = 1 ]; then
  [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
  [ -x /usr/bin/clear ] && /usr/bin/clear
fi
