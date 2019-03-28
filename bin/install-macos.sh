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
		# Set xcode directory
		XCODE_DIRECTORY=/Applications/Xcode.app/Contents/Developer
		echo "Setting Xcode directory to $XCODE_DIRECTORY"
		sudo xcode-select -s "$XCODE_DIRECTORY"

		echo "Accepting Xcode license"
		sudo xcodebuild -license accept

		if ! xcode-select -p >/dev/null 2>&1; then
			echo "Installing Xcode CLI"
			xcode-select --install
		else
			echo "Xcode is already installed"
		fi

		# Create dirs
		echo "Initializing Homebrew Cellar path: ${HOMEBREW_CELLAR}, Homebrew repository path: ${HOMEBREW_REPOSITORY} and Homebrew path: ${HOMEBREW_PATH}"

		HOMEBREW_BIN_PATH="${HOMEBREW_PATH}"/bin
		sudo install -d -o "$(whoami)" "${HOMEBREW_CELLAR}" "${HOMEBREW_PATH}" "${HOMEBREW_BIN_PATH}" "${HOMEBREW_REPOSITORY}"

		# Download and install Homebrew
		echo "Installing Homebrew"
		cd "${HOMEBREW_REPOSITORY}"
		git init -q
		git config remote.origin.url "https://github.com/Homebrew/brew"
		git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
		git config core.autocrlf false
		git fetch origin master:refs/remotes/origin/master --tags --force
		git reset --hard origin/master
		ln -s "${HOMEBREW_REPOSITORY}"/bin/brew "${HOMEBREW_BIN_PATH}"/brew
	else
		echo "Homebrew is already installed"
	fi

	echo "Disabling homebrew usage analytics"
	brew analytics off
}

install_brew_formulae() {
	# Make sure we’re using the latest Homebrew and formulae
	update_brew

	# Save Homebrew’s installed location.
	BREW_PREFIX="$(brew --prefix)"

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
	brew install bash-completion@2

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

patch_brew(){
	cd "$HOMEBREW_REPOSITORY"
	if ! patch -R -p0 -s -f --dry-run < "$DOTFILES_LIB_PATH"/homebrew-cellar.patch >/dev/null 2>&1; then
		echo "Patching Homebrew (in $HOMEBREW_REPOSITORY) to let users set the Cellar path (currently set to: $HOMEBREW_CELLAR)"
		patch -p0 < "$DOTFILES_LIB_PATH"/homebrew-cellar.patch
	else
		echo "Homebrew (in $HOMEBREW_REPOSITORY) is already patched to allow a customized Cellar path"
	fi
}

update_brew() {
	brew update
	brew upgrade

	# Check if we need to patch homebrew (if it was updated)
	patch_brew

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
		echo "  homebrew-formulae                   - install Homebrew formulae"
		echo "  update                              - update the system"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	ask_for_sudo

	if [[ $cmd == "homebrew" ]]; then
		install_brew
		patch_brew
  elif [[ $cmd == "homebrew-formulae" ]]; then
    install_brew_formulae
  elif [[ $cmd == "update" ]]; then
    update_system
	fi
}

main "$@"
