#!/usr/bin/env bash

ask_for_sudo() {
    echo "Prompting for sudo password..."
    if sudo --validate; then
        # Keep-alive
        while true; do sudo --non-interactive true; \
            sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        echo "Sudo credentials updated."
    else
        echo "Obtaining sudo credentials failed."
        exit 1
    fi
}

install_brew() {
    # Run this to silently accept the Xcode license agreement
    sudo xcodebuild -license accept

	HOMEBREW_HOME="$HOME"/homebrew
    mkdir "$HOMEBREW_HOME"
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOMEBREW_HOME"
}

usage() {
    echo -e "install-macos.sh\\n\\tThis script installs my basic setup for a MacOS workstation\\n"
}

main() {
	usage
	ask_for_sudo
	install_brew
}

main "$@"