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
    # Save Homebrew’s installed location.
    BREW_PREFIX="$(brew --prefix)"

    for f in \
        ansible \
        bash \
        bash-completion \
        coreutils \
        docker-compose \
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

    # for f in \
    #     docker \
    #     google-cloud-sdk \
    #     iterm2 \
    #     virtualbox \
    #     visual-studio-code; do
    #     if ! brew cask ls --versions "$f" >/dev/null; then
    #         echo "Installing $f cask"
    #         brew cask install "$f"
    #     else
    #         echo "$f cask is already installed"
    #     fi
    # done

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

install_npm_packages() {
    if command -v npm >/dev/null 2>&1; then
        echo "Installing NPM packages"
        for f in \
            @google/clasp \
            markdownlint-cli; do
            npm list -g "$f" || npm install -g "$f"
        done
    else
        echo "WARNING: npm is not installed. Skipping npm package installation."
    fi
}

install_rubygems() {
    if command -v gem >/dev/null 2>&1; then
        echo "Installing Ruby gems"
        sudo gem update
        sudo gem install \
            bundler
    else
        echo "WARNING: gem is not installed. Skipping ruby gems installation."
    fi
}

setup_user() {
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Pictures/workspaces"
}

setup_debian() {
    echo "Setting up a Debian system"

    echo "Installing the minimal set of packages"
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

    distribution="$(lsb_release -d | awk -F"\t" '{print $2}')"
    reqsubstr="rodete"

    # If we're not in rodete
    if [ -n "${distribution##*$reqsubstr*}" ]; then
        echo "Adding the main APT repository"
        sudo add-apt-repository main

        case "$distribution" in
        Ubuntu*)
            echo "Adding other Ubuntu-specific APT repositories"
            sudo add-apt-repository universe
            sudo add-apt-repository multiverse
            sudo add-apt-repository restricted
            ;;
        *) false ;;
        esac
    fi

    # Add the Google Chrome distribution URI as a package source if needed
    # Don't install it if we're in crostini (Chrome OS linux environment) or if it's already installed
    if ! [ -d "/opt/google/cros-containers" ] && ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
        echo "Installing Chrome browser..."
        curl -fsLo google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
        rm ./google-chrome-stable_current_amd64.deb
        sudo apt-get install -f
    else
        echo "Google Chrome is already installed"
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
        libgdbm-dev \
        libgdbm-compat-dev \
        libpam-systemd \
        libssl-dev \
        locales \
        lsof \
        make \
        mount \
        nano \
        net-tools \
        pinentry-curses \
        rbenv \
        ruby-dev \
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
        zlib1g-dev \
        zsh \
        --no-install-recommends

    sudo apt-get -y autoremove
    sudo apt-get -y autoclean
    sudo apt-get -y clean

    if ! command -v docker >/dev/null 2>&1; then
        echo "Installing Docker"
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

        docker_distribution=
        case "$distribution" in
        Ubuntu*)
            docker_distribution="ubuntu"
            ;;
        Debian*)
            docker_distribution="debian"
            ;;
        *) exit 1 ;;
        esac

        sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/${docker_distribution} \
            $(lsb_release -cs) \
            stable"
        sudo apt-get update
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io

        unset docker_distribution
    fi

    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "Getting Docker Compose version to install"
        docker_compose_release="$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
        echo "Installing Docker Compose $docker_compose_release"
        sudo curl -fsLo /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/"$docker_compose_release"/docker-compose-"$(uname -s)"-"$(uname -m)"
        sudo chmod a+x /usr/local/bin/docker-compose
    fi

    # add user to sudoers
    sudo gpasswd -a "$TARGET_USER" sudo

    # create docker group
    getent group docker >/dev/null 2>&1 || sudo groupadd docker

    # Add user docker group
    sudo gpasswd -a "$TARGET_USER" docker
}

setup_macos() {
    echo "Setting up macOS"

    ###############################################################################
    # General UI/UX                                                               #
    ###############################################################################

    echo "Configuring macOS UI/UX"

    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" "

    # Enable the sound effects on boot
    #sudo nvram SystemAudioVolume="7"

    ###############################################################################
    # Mac App Store                                                               #
    ###############################################################################

    echo "Configuring macOS App Store"

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

    echo "Configuring macOS Dock"

    # Change minimize/maximize window effect
    defaults write com.apple.dock mineffect -string "scale"

    # Minimize windows into their application’s icon
    defaults write com.apple.dock minimize-to-application -bool true

    ###############################################################################
    # Terminal & iTerm 2                                                          #
    ###############################################################################

    echo "Configuring macOS Terminal"

    # Only use UTF-8 in Terminal.app
    defaults write com.apple.terminal StringEncodings -array 4

    # Don’t display the annoying prompt when quitting iTerm
    defaults write com.googlecode.iterm2 PromptOnQuit -bool false

    ###############################################################################
    # Trackpad                                                                    #
    ###############################################################################

    echo "Configuring macOS Trackpad"

    # Trackpad: enable tap to click for this user
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

    # Trackpad: enable tap to click for the login screen
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    ###############################################################################
    # Menu bar                                                                    #
    ###############################################################################

    echo "Configuring macOS menu bar"

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

    echo "Configuring Adobe stuff in macOS"

    # Kill those processes
    killall AGSService ACCFinderSync "Core Sync" AdobeCRDaemon "Adobe Creative" AdobeIPCBroker node "Adobe Desktop Service" "Adobe Crash Reporter" CCXProcess CCLibrary || true

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

    echo "Killing and restarting affected apps"

    for app in "Activity Monitor" \
        "cfprefsd" \
        "Dock" \
        "Finder" \
        "SystemUIServer" \
        "Terminal"; do
        killall "${app}" &>/dev/null || true
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
    font_dir=
    user_default_shell=
    if test "${os_name#*"Darwin"}" != "$os_name"; then
        font_dir="$HOME/Library/Fonts"
        user_default_shell="$(dscl . -read ~/ UserShell | sed 's/UserShell: //')"
    elif test "${os_name#*"Linux"}" != "$os_name"; then
        font_dir="$HOME/.local/share/fonts"
        user_default_shell="$(awk -F: -v user="$USER" '$1 == user {print $NF}' /etc/passwd)"
    fi
    unset os_name

    echo "Downloading fonts in ${font_dir}"
    font_dir="${font_dir}/NerdFonts"
    mkdir -p "${font_dir}"
    ! [ -e "${font_dir}/MesloLGS NF Regular.ttf" ] && curl -fsLo "${font_dir}/MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    ! [ -e "${font_dir}/MesloLGS NF Bold.ttf" ] && curl -fsLo "${font_dir}/MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    ! [ -e "${font_dir}/MesloLGS NF Italic.ttf" ] && curl -fsLo "${font_dir}/MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    ! [ -e "${font_dir}/MesloLGS NF Bold Italic.ttf" ] && curl -fsLo "${font_dir}/MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

    if [ "$user_default_shell" != "$DEFAULT_SHELL" ]; then
        echo "Changing default shell to $DEFAULT_SHELL"
        chsh -s "$DEFAULT_SHELL"
    fi

    unset font_dir
    unset user_default_shell
    echo "The default shell is set to $DEFAULT_SHELL"
}

usage() {
    echo -e "setup-dotfiles.sh\\n\\tThis script installs my basic setup for a workstation\\n"
    echo "Usage:"
    echo "  debian                              - install base packages on a Debian system"
    echo "  macos                               - setup macOS"
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
        setup_shell
        setup_user
        install_npm_packages
        install_rubygems
    elif [[ $cmd == "macos" ]]; then
        setup_macos
        setup_shell
        setup_user
        install_brew
        install_brew_formulae
        install_npm_packages
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
