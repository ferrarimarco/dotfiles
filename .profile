# WARNING: if you delete .bash_profile, this file becomes part of bash's startup
# sequence, which means this file suddenly has to cater for two different
# shells.

# shellcheck shell=sh

# shellcheck source=/dev/null
. "$HOME"/.shells/.sh/environment.sh

# shellcheck source=/dev/null
. "$HOME"/.shells/.sh/login.sh
