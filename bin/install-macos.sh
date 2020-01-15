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
		echo "Initializing Homebrew repository path: ${HOMEBREW_REPOSITORY} and Homebrew path: ${HOMEBREW_PATH}"

		HOMEBREW_BIN_PATH="${HOMEBREW_PATH}"/bin
		sudo install -d -o "$(whoami)" "${HOMEBREW_PATH}" "${HOMEBREW_BIN_PATH}" "${HOMEBREW_REPOSITORY}"

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

	for f in \
		bash \
		bash-completion \
		coreutils \
		findutils \
		gawk \
		git \
		gnupg \
		gnu-getopt \
		gnu-indent \
		gnu-sed \
		gnu-tar \
		grep \
		make \
		nano \
		p7zip \
		rbenv \
		shellcheck \
		terraform \
		tflint \
		tree \
		vagrant \
		wget \
		zsh \
		zsh-autosuggestions \
		zsh-syntax-highlighting
	do
		if ! brew ls --versions "$f" > /dev/null; then
			echo "Installing $f"
			while true; do
				read -r -p "Build from source? (y/n) "  yn
				case $yn in
					[Yy]* ) brew_install_recursive_build_from_source "$f"; break;;
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
		virtualbox \
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
		echo "Add bash installed via brew to the list of allowed shells"
		echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
	fi

	if ! grep -Fq "${BREW_PREFIX}/bin/zsh" /etc/shells;
	then
		echo "Add zsh installed via brew to the list of allowed shells"
		echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;

		echo "Changing default shell to zsh"
		chsh -s "${BREW_PREFIX}/bin/zsh";
	fi

	echo "Removing outdated versions from the cellar."
	brew cleanup

	echo "Setting up Visual Studio Code"
	local _vs_code_settings_dir="$HOME"/Library/Application\ Support/Code/User
	local _vs_code_settings_path="$_vs_code_settings_dir"/settings.json
	ln -sfn "$HOME"/.config/Code/User/settings.json "$_vs_code_settings_path"
	unset _vs_code_settings_path
	unset _vs_code_settings_dir

	while IFS= read -r line; do
		code --install-extension "$line"
	done < "$HOME"/.config/Code/extensions.txt
}

setup_macos(){
	###############################################################################
	# General UI/UX                                                               #
	###############################################################################

	# Disable the sound effects on boot
	sudo nvram SystemAudioVolume=" "

	# Enable the sound effects on boot
	#sudo nvram SystemAudioVolume="7"

	###############################################################################
	# Mac App Store                                                               #
	###############################################################################

	# Enable the automatic update check
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool true

	# Check for software updates daily, not just once per week
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ScheduleFrequency -int 1

	# Download newly available updates in background
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -int 1

	# Install System data files & security updates
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -int 1

	# Automatically download apps purchased on other Macs
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall -int 1

	# Automatically install macOS Updates
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates -int 1

	# Turn on app auto-update in App Store
	sudo defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdate -bool true

	# Allow the App Store to reboot machine on macOS updates
	sudo defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdateRestartRequired -bool true

	# Enable automatic updates in System Preferences -> Software Update -> Advanced -> Check for updates
	sudo softwareupdate --schedule ON

	###############################################################################
	# Dock                                                                        #
	###############################################################################

	# Change minimize/maximize window effect
	defaults write com.apple.dock mineffect -string "scale"

	# Minimize windows into their application’s icon
	defaults write com.apple.dock minimize-to-application -bool true

	###############################################################################
	# Terminal & iTerm 2                                                          #
	###############################################################################

	# Only use UTF-8 in Terminal.app
	defaults write com.apple.terminal StringEncodings -array 4

	# Don’t display the annoying prompt when quitting iTerm
	defaults write com.googlecode.iterm2 PromptOnQuit -bool false

	###############################################################################
	# Trackpad                                                                    #
	###############################################################################

	# Trackpad: enable tap to click for this user
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

	# Trackpad: enable tap to click for the login screen
	defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

	###############################################################################
	# Menu bar                                                                    #
	###############################################################################

	# Show icons in the menu bar
	defaults write com.apple.systemuiserver menuExtras -array \
	"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
	"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
	"/System/Library/CoreServices/Menu Extras/Clock.menu" \
	"/System/Library/CoreServices/Menu Extras/Volume.menu"

	# Ensure we're using a digital clock
	defaults write com.apple.menuextra.clock IsAnalog -bool false

	# Show date and time in the menu bar
	defaults write com.apple.menuextra.clock "DateFormat" "EEE d MMM HH:mm:ss"

	# Don't flash time and date separators
	defaults write com.apple.menuextra.clock FlashDateSeparators -bool false

	###############################################################################
	# Adobe stuff                                                                 #
	###############################################################################

	# Kill those processes
	killall AGSService ACCFinderSync "Core Sync" AdobeCRDaemon "Adobe Creative" AdobeIPCBroker node "Adobe Desktop Service" "Adobe Crash Reporter" CCXProcess CCLibrary

	# Disable Adobe autostart agents and daemons
	for i in /Library/LaunchAgents/com.adobe* \
		"$HOME"/Library/LaunchAgents/com.adobe* \
		/Library/LaunchDaemons/com.adobe* \
		/System/Library/LaunchAgents/com.adobe* \
		/System/Library/LaunchDaemons/com.adobe*; do

		# Exit the loop if there are no matching files
		# Safeguard for when nullglob is disabled in bash
		[ -f "$i" ] || break

		# Disable the agent
		launchctl unload -w "$i" 2>/dev/null

		# Avoid further edits
		sudo chmod 000 "$i"
	done

	# Disable the "Core Sync" finder extension
	if defaults read "com.apple.finder.SyncExtensions" 2>/dev/null; then
		defaults delete "com.apple.finder.SyncExtensions"
	fi

	# Remove the "Core Sync" finder extension
	sudo rm -rf "/Applications/Utilities/Adobe Sync/CoreSync/Core Sync.app"

	###############################################################################
	# Kill affected applications                                                  #
	###############################################################################

	for app in "Activity Monitor" \
		"cfprefsd" \
		"Dock" \
		"Finder" \
		"SystemUIServer" \
		"Terminal"; do
		killall "${app}" &> /dev/null
	done
	echo "Done. Note that some of these changes require a logout/restart to take effect."
}

setup_shell() {
	# Download ZSH themes
	CURRENT_ZSH_THEME_DIR="$(dirname "$ZSH_THEME_PATH")"
	rm -rf "$CURRENT_ZSH_THEME_DIR"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$CURRENT_ZSH_THEME_DIR"
	unset CURRENT_ZSH_THEME_DIR
}

update_brew() {
	echo "Upgrading brew and formulae"
    brew update

	while true; do
		read -r -p "Build homebrew upgrades from source? (y/n) "  yn
		case $yn in
			[Yy]* ) brew upgrade --build-from-source; break;;
			[Nn]* ) brew upgrade; break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

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
		echo "  macos                               - setup macOS"
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
	elif [[ $cmd == "homebrew-formulae" ]]; then
		install_brew
		install_brew_formulae
	elif [[ $cmd == "macos" ]]; then
		setup_macos
		setup_shell
	elif [[ $cmd == "update" ]]; then
		update_system
		setup_shell
	fi
}

main "$@"
