#!/usr/bin/env bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

ask_for_sudo() {
    echo "Prompting for sudo password..."
    if sudo -v; then
        # Keep-alive
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        echo "Sudo credentials updated."
    else
        echo "Obtaining sudo credentials failed."
        exit 1
    fi
}

# Choose a user account to use for this installation
get_user() {
    TARGET_USER=${USER:-${USERNAME:-${LOGNAME}}}
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
        shfmt \
        terraform \
        tflint \
        tree \
        vagrant \
        wget \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting; do
        if ! brew ls --versions "$f" >/dev/null; then
            echo "Installing $f"
            while true; do
                read -r -p "Build from source? (y/n) " yn
                case $yn in
                [Yy]*)
                    brew_install_recursive_build_from_source "$f"
                    break
                    ;;
                [Nn]*)
                    brew install "$f"
                    break
                    ;;
                *) echo "Please answer yes or no." ;;
                esac
            done
        else
            echo "$f is already installed"
        fi
    done

    for f in \
        google-cloud-sdk \
        iterm2 \
        virtualbox \
        visual-studio-code; do
        if ! brew cask ls --versions "$f" >/dev/null; then
            echo "Installing $f cask"
            brew cask install "$f"
        else
            echo "$f cask is already installed"
        fi
    done

    if ! grep -Fq "${BREW_PREFIX}/bin/bash" /etc/shells; then
        echo "Add bash installed via brew to the list of allowed shells"
        echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
    fi

    if ! grep -Fq "${BREW_PREFIX}/bin/zsh" /etc/shells; then
        echo "Add zsh installed via brew to the list of allowed shells"
        echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells
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
    done <"$HOME"/.config/Code/extensions.txt
}

install_npm() {
    npm install -g \
        @google/clasp
}

install_rubygems() {
    gem install \
        bundler
}

setup_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo "Docker is already installed"
    else
        curl -sSL https://get.docker.com | sh

        # create docker group
        getent group docker >/dev/null 2>&1 || groupadd docker
        gpasswd -a "$TARGET_USER" docker
    fi

    if command -v docker-compose >/dev/null 2>&1; then
        echo "Docker Compose is already installed"
    else
        docker_compose_release="$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
        curl -sL https://github.com/docker/compose/releases/download/"$docker_compose_release"/docker-compose-"$(uname -s)"-"$(uname -m)" -o /usr/local/bin/docker-compose
        chmod a+x /usr/local/bin/docker-compose
    fi
}

# setup sudo for a user
setup_sudo() {
    # add user to sudoers
    sudo adduser "$TARGET_USER" sudo
}

setup_user() {
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Pictures/workspaces"
}

setup_debian() {
    sudo apt-get update || true
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        dirmngr \
        gnupg2 \
        lsb-release \
        software-properties-common \
        --no-install-recommends

    sudo add-apt-repository main

    if case $(lsb_release -d | awk -F"\t" '{print $2}') in Ubuntu*) true ;; *) false ;; esac then
        sudo add-apt-repository universe
        sudo add-apt-repository multiverse
        sudo add-apt-repository restricted
    fi

    # Add the Google Chrome distribution URI as a package source if needed
    if ! [ -d "/opt/google/cros-containers" ]; then
        echo "Installing Chrome browser..."
        curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
        rm ./google-chrome-stable_current_amd64.deb
        sudo apt-get install -f
    fi

    sudo apt-get update || true
    sudo apt-get -y upgrade

    sudo apt-get install -y \
        adduser \
        alsa-utils \
        apparmor \
        automake \
        bash-completion \
        bc \
        bridge-utils \
        bzip2 \
        coreutils \
        dbus-user-session \
        dnsutils \
        file \
        findutils \
        fwupd \
        fwupdate \
        gcc \
        git \
        glogg \
        gnupg \
        gnupg-agent \
        grep \
        gzip \
        hostname \
        imagemagick \
        iptables \
        jmeter \
        less \
        libc6-dev \
        libpam-systemd \
        locales \
        lsof \
        make \
        mount \
        nano \
        net-tools \
        pinentry-curses \
        rxvt-unicode \
        scdaemon \
        ssh \
        strace \
        sudo \
        systemd \
        tar \
        tree \
        tzdata \
        unzip \
        xclip \
        xcompmgr \
        xz-utils \
        zip \
        zsh \
        --no-install-recommends

    sudo apt-get autoremove
    sudo apt-get autoclean
    sudo apt-get clean
}

setup_macos() {
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
        killall "${app}" &>/dev/null
    done
    echo "Done. Note that some of these changes require a logout/restart to take effect."
}

setup_shell() {
    echo "Setting up the shell..."

    # Download ZSH themes
    CURRENT_ZSH_THEME_DIR="$(dirname "$ZSH_THEME_PATH")"
    rm -rf "$CURRENT_ZSH_THEME_DIR"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$CURRENT_ZSH_THEME_DIR"
    unset CURRENT_ZSH_THEME_DIR

    local os_name
    os_name="$(uname -s)"
    user_default_shell=
    if test "${os_name#*"Darwin"}" != "$os_name"; then
        user_default_shell="$(dscl . -read ~/ UserShell | sed 's/UserShell: //')"
    elif test "${os_name#*"Linux"}" != "$os_name"; then
        user_default_shell="$(awk -F: -v user="$USER" '$1 == user {print $NF}' /etc/passwd)"
    fi
    unset os_name

    if [ "$user_default_shell" != "$DEFAULT_SHELL" ]; then
        echo "Changing default shell to $DEFAULT_SHELL"
        chsh -s "$DEFAULT_SHELL"
    fi
    unset user_default_shell
    echo "The default shell is set to $DEFAULT_SHELL"
}

update_brew() {
    echo "Upgrading brew and formulae"
    brew update

    while true; do
        read -r -p "Build homebrew upgrades from source? (y/n) " yn
        case $yn in
        [Yy]*)
            brew upgrade --build-from-source
            break
            ;;
        [Nn]*)
            brew upgrade
            break
            ;;
        *) echo "Please answer yes or no." ;;
        esac
    done

    echo "Cleaning up brew..."
    brew cleanup -s

    echo "Checking for missing brew formula kegs..."
    brew missing
}

update_system() {
    local os_name
    os_name="$(uname -s)"
    if test "${os_name#*"Darwin"}" != "$os_name"; then
        echo "Updating macOS..."
        sudo softwareupdate -ia
        update_brew
    elif test "${os_name#*"Linux"}" != "$os_name"; then
        echo "Updating linux..."
    fi
    unset os_name
}

usage() {
    echo -e "setup-dotfiles.sh\\n\\tThis script installs my basic setup for a workstation\\n"
    echo "Usage:"
    echo "  debian                              - install base packages on a Debian system"
    echo "  docker                              - install docker"
    echo "  macos                               - setup macOS"
    echo "  npm                                 - install npm packages"
    echo "  rubygems                            - install Ruby gems"
    echo "  update                              - update the system"
}

main() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    ask_for_sudo
    get_user

    if [[ $cmd == "debian" ]]; then
        setup_debian
        setup_sudo
        setup_shell
        setup_user
    elif [[ $cmd == "docker" ]]; then
        setup_docker
    elif [[ $cmd == "macos" ]]; then
        setup_macos
        setup_shell
        setup_user
        install_brew
        install_brew_formulae
    elif [[ $cmd == "npm" ]]; then
        install_npm
    elif [[ $cmd == "rubygems" ]]; then
        install_rubygems
    elif [[ $cmd == "update" ]]; then
        echo "Updating the system..."
        update_system
        setup_shell
    else
        usage
    fi
}

main "$@"
