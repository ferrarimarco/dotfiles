#!/usr/bin/env sh

# Create a new directory and enter it
mkd() {
	mkdir -p "$@"
	cd "$@" || exit
}

# If you install brew formulae from source, you may want to install its
# deps from source as well
brew_install_recursive_build_from_source() {
	echo "Installing $* and it's deps from source"
	brew deps --include-build --include-optional -n  "$@" | while read -r line ; do
		brew install --build-from-source "$line"
	done
	brew install --build-from-source "$@"
}

# Make a temporary directory and enter it
tmpd() {
	dir=
	if [ $# -eq 0 ]; then
		dir=$(mktemp -d)
	else
		dir=$(mktemp -d -t "${1}.XXXXXXXXXX")
	fi
	cd "$dir" || exit
	unset dir
}

# Use Git’s colored diff when available
if command -v git > /dev/null 2>&1; then
	diff() {
		git diff --no-index --color-words "$@"
	}
fi;

# Get colors in manual pages
man() {
	env \
		LESS_TERMCAP_mb="$(printf '\e[1;31m')" \
		LESS_TERMCAP_md="$(printf '\e[1;31m')" \
		LESS_TERMCAP_me="$(printf '\e[0m')" \
		LESS_TERMCAP_se="$(printf '\e[0m')" \
		LESS_TERMCAP_so="$(printf '\e[1;44;33m')" \
		LESS_TERMCAP_ue="$(printf '\e[0m')" \
		LESS_TERMCAP_us="$(printf '\e[1;32m')" \
		man "$@"
}
