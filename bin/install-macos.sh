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
		cd "${HOMEBREW_REPOSITORY}" || exit
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

	# Source .functions to access the brew-install-recursive-build-from-source function
	# shellcheck source=/dev/null
	source "${HOME}"/.functions

	for f in \
		bash \
		bash-completion \
		coreutils \
		findutils \
		gawk \
		git \
		git-lfs \
		gnupg \
		gnutls \
		gnu-getopt \
		gnu-indent \
		gnu-sed \
		gnu-tar \
		grep \
		make \
		p7zip \
		rbenv \
		terraform \
		tree \
		wget
	do
		if ! brew ls --versions "$f" > /dev/null; then
			echo "Installing $f"
			while true; do
				read -r -p "Build from source? (y/n) "  yn
				case $yn in
					[Yy]* ) brew-install-recursive-build-from-source "$f"; break;;
					[Nn]* ) brew install "$f"; break;;
					* ) echo "Please answer yes or no.";;
				esac
			done
		else
			echo "$f is already installed"
		fi
	done

	for f in \
		google-cloud-sdk \
		visual-studio-code
	do
		if ! brew cask ls --versions "$f" > /dev/null; then
			echo "Installing $f cask"
			brew cask install "$f"
		else
			echo "$f cask is already installed"
		fi
	done

	if ! grep -Fq "${BREW_PREFIX}/bin/bash" /etc/shells;
	then
		echo "Switching to using brew-installed bash as default shell"
		echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
		chsh -s "${BREW_PREFIX}/bin/bash";
	fi

	echo "Removing outdated versions from the cellar."
	brew cleanup
}

patch_brew(){
	cd "$HOMEBREW_REPOSITORY" || exit
	if ! patch -R -p0 -s -f --dry-run < "$DOTFILES_LIB_PATH"/homebrew-cellar.patch >/dev/null 2>&1; then
		echo "Patching Homebrew (in $HOMEBREW_REPOSITORY) to let users set the Cellar path (currently set to: $HOMEBREW_CELLAR)"
		patch -p0 < "$DOTFILES_LIB_PATH"/homebrew-cellar.patch
	else
		echo "Homebrew (in $HOMEBREW_REPOSITORY) is already patched to allow a customized Cellar path"
	fi
}

update_brew() {
	BUILD_FROM_SOURCE_SWITCH=""
	while true; do
		read -r -p "Build from source? (y/n) "  yn
		case $yn in
			[Yy]* ) BUILD_FROM_SOURCE_SWITCH="--build-from-source"; break;;
			[Nn]* ) BUILD_FROM_SOURCE_SWITCH=""; break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	echo "Build from source switch set to: $BUILD_FROM_SOURCE_SWITCH"

	brew upgrade "$BUILD_FROM_SOURCE_SWITCH"

	# Check if we need to patch homebrew (if it was updated)
	patch_brew

	brew cleanup -s

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
		install_brew
		patch_brew
		install_brew_formulae
	elif [[ $cmd == "update" ]]; then
		update_system
	fi
}

main "$@"
