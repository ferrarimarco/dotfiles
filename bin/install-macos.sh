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
	if ! command -v brew >/dev/null 2>&1; then
		echo "Installing Homebrew"
		# Run this to silently accept the Xcode license agreement
		sudo xcodebuild -license accept

		# Install XCode CLI
		xcode-select --install

		HOMEBREW_HOME="$HOME"/homebrew
		mkdir -p "$HOMEBREW_HOME"
		curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOMEBREW_HOME"
	else
		echo "Homebrew is already installed"
	fi
}

install_brew_formulae() {
	# Make sure we’re using the latest Homebrew.
	brew update

	# Upgrade any already-installed formulae.
	brew upgrade

	# Save Homebrew’s installed location.
	BREW_PREFIX=$(brew --prefix)

	# Install GNU core utilities (those that come with macOS are outdated).
	# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
	brew install coreutils
	ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

	# Install some other useful utilities like `sponge`.
	brew install moreutils
	# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
	brew install findutils
	# Install GNU `sed`, overwriting the built-in `sed`.
	brew install gnu-sed --with-default-names
	# Install Bash 4.
	brew install bash
	brew install bash-completion2

	# Switch to using brew-installed bash as default shell
	if ! grep -Fq "${BREW_PREFIX}/bin/bash" /etc/shells; then
		echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
		chsh -s "${BREW_PREFIX}/bin/bash";
	fi;

	# Install `wget` with IRI support.
	brew install wget --with-iri

	# Install GnuPG to enable PGP-signing commits.
	brew install gnupg

	# Install more recent versions of some macOS tools.
	brew install vim --with-override-system-vi
	brew install grep
	brew install openssh
	brew install screen
	brew install homebrew/php/php56 --with-gmp

	# Install other useful binaries.
	brew install git
	brew install git-lfs
	brew install imagemagick --with-webp
	brew install p7zip
	brew install tree

	# Remove outdated versions from the cellar.
	brew cleanup
}

update_brew() {
	brew update
	brew upgrade
	brew cleanup -s
	brew cask cleanup

	brew doctor
	brew missing
}

update_system() {
	sudo softwareupdate -ia
	update_brew
}

usage() {
		echo -e "install-macos.sh\\n\\tThis script installs my basic setup for a MacOS workstation\\n"
		echo "  homebrew                            - install Homebrew"
		echo "  update                              - update the system"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	ask_for_sudo

	if [[ $cmd == "brew" ]]; then
		install_brew
		install_brew_formulae
  elif [[ $cmd == "update" ]]; then
    update_system
	fi
}

main "$@"
