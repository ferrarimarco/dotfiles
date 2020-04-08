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
    echo "Set user to $TARGET_USER"
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
        go \
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
        zsh-completions \
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

    while true; do
        read -r -p "Install casks? (y/n) " yn
        case $yn in
        [Yy]*)
            for f in \
                docker \
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
            break
            ;;
        [Nn]*)
            echo "Skipping cask installation"
            break
            ;;
        *) echo "Please answer yes or no." ;;
        esac
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
        code --force --install-extension "$line"
    done <"$HOME"/.config/ferrarimarco-dotfiles/vs-code/extensions.txt
}

install_go_packages() {
    if command -v go >/dev/null 2>&1; then
        echo "Installing go packages"
        for f in \
            github.com/mdempsky/gocode \
            github.com/ramya-rao-a/go-outline \
            github.com/rogpeppe/godef \
            github.com/sqs/goreturns \
            github.com/stamblerre/gocode \
            github.com/uudashr/gopkgs/v2/cmd/gopkgs \
            golang.org/x/lint/golint \
            golang.org/x/tools/cmd/goimports \
            mvdan.cc/sh/v3/cmd/shfmt; do
            go list "$f" >/dev/null 2>&1 || echo "Installing $f" && go get "$f"
        done
    else
        echo "WARNING: go is not installed. Skipping go package installation."
    fi
}

install_npm_packages() {
    if command -v npm >/dev/null 2>&1; then
        echo "Installing NPM packages"
        for f in \
            @google/clasp \
            markdownlint-cli; do
            npm list -g "$f" || sudo npm install -g "$f"
        done
    else
        echo "WARNING: npm is not installed. Skipping npm package installation."
    fi
}

install_python_packages() {
    if command -v pip3 >/dev/null 2>&1; then
        echo "Installing Python 3 packages"
        sudo pip3 install \
            black \
            setuptools \
            yamllint
    else
        echo "WARNING: pip3 is not installed. Skipping Python 3 package installation."
    fi
}

install_rubygems() {
    if command -v gem >/dev/null 2>&1; then
        echo "Installing Ruby gems"
        sudo gem update
        sudo gem install \
            bundler \
            travis
    else
        echo "WARNING: gem is not installed. Skipping ruby gems installation."
    fi
}

setup_user() {
    mkdir -p "$HOME/.go"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Pictures/Screenshots"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/workspaces"
}

setup_debian() {
    echo "Setting up a Debian system"

    echo "Installing the minimal set of packages"
    sudo apt-get update || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        dialog \
        dirmngr \
        git \
        gnupg2 \
        locales \
        lsb-release \
        software-properties-common \
        --no-install-recommends

    echo "Ensuring the $LANG locale is available..."
    sudo locale-gen "$LANG"
    sudo dpkg-reconfigure --frontend=noninteractive locales
    sudo update-locale LANG="$LANG" LANGUAGE="$LANGUAGE" LC_ALL="$LC_ALL"

    distribution="$(lsb_release -d | awk -F"\t" '{print $2}')"
    reqsubstr="rodete"

    # If we're not in rodete
    if [ -n "${distribution##*$reqsubstr*}" ]; then
        echo "Adding the main APT repository"
        sudo add-apt-repository "main"

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

        echo "Downloading Chrome package..."
        TEMP_DIRECTORY="$(mktemp -d)"
        CHROME_ARCHIVE_NAME=google-chrome-stable_current_amd64.deb
        CHROME_ARCHIVE_PATH="$TEMP_DIRECTORY/$CHROME_ARCHIVE_NAME"
        curl -fsLo "$CHROME_ARCHIVE_PATH" https://dl.google.com/linux/direct/"$CHROME_ARCHIVE_NAME"

        echo "Making the temporary directory world-accessible..."
        chmod -Rv 777 "$TEMP_DIRECTORY"

        echo "Installing Chrome package..."
        sudo apt-get install -y "$CHROME_ARCHIVE_PATH"

        echo "Removing Chrome package..."
        rm "$CHROME_ARCHIVE_PATH"

        echo "Removing the temporary directory..."
        rm -rf "$TEMP_DIRECTORY"

        echo "Installing missing dependencies..."
        sudo apt-get install -f

        unset TEMP_DIRECTORY
        unset CHROME_ARCHIVE_NAME
        unset CHROME_ARCHIVE_PATH

    else
        echo "Google Chrome is already installed"
    fi

    # Download zsh-autosuggestions
    if [ -z "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH" ]; then
        echo "The ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH variable is not set, or set to an empty string"
        exit 1
    fi

    CURRENT_ZSH_AUTOSUGGESTIONS_DIR="$(dirname "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH")"
    if [ -d "$CURRENT_ZSH_AUTOSUGGESTIONS_DIR" ]; then
        echo "Updating zsh-autosuggestions in: $CURRENT_ZSH_AUTOSUGGESTIONS_DIR"
        git -C "$CURRENT_ZSH_AUTOSUGGESTIONS_DIR" pull
    else
        echo "Downloading zsh-autosuggestions in: $CURRENT_ZSH_AUTOSUGGESTIONS_DIR"
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$CURRENT_ZSH_AUTOSUGGESTIONS_DIR"
    fi

    sudo apt-get update || true
    sudo apt-get -y upgrade

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        adduser \
        alsa-utils \
        apparmor \
        automake \
        bash-completion \
        bc \
        bridge-utils \
        build-essential \
        bzip2 \
        coreutils \
        dnsutils \
        file \
        findutils \
        fwupd \
        fwupdate \
        gcc \
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
        python3-pip \
        rbenv \
        ruby-dev \
        rxvt-unicode \
        scdaemon \
        shellcheck \
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

    if ! command -v node >/dev/null 2>&1; then
        echo "Installing Node.js"
        curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if ! command -v go >/dev/null 2>&1; then
        GO_VERSION=1.14.1
        echo "Installing go $GO_VERSION..."
        GO_ARCHIVE_NAME=go"$GO_VERSION".linux-amd64.tar.gz
        TEMP_DIRECTORY="$(mktemp -d)"
        curl -fsLo "$TEMP_DIRECTORY/$GO_ARCHIVE_NAME" https://dl.google.com/go/"$GO_ARCHIVE_NAME"

        echo "Extracting go archive..."
        mkdir -p "$GOROOT"
        tar -C "$GOROOT" --strip-components=1 -xzf "$TEMP_DIRECTORY/$GO_ARCHIVE_NAME"

        mkdir -p "$GOPATH"/{src,pkg,bin}
        rm -f "$TEMP_DIRECTORY/$GO_ARCHIVE_NAME"
        echo "Installed go $GO_VERSION. Verifying with go version: $(go version)"
        unset GO_VERSION
        unset GO_ARCHIVE_NAME
        unset TEMP_DIRECTORY
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
        killall "${app}" >/dev/null 2>&1 || true
    done
    echo "Done. Note that some of these changes require a logout/restart to take effect."
}

setup_shell() {
    echo "Setting up the shell..."

    if [ -z "$ZSH_THEME_PATH" ]; then
        echo "The ZSH_THEME_PATH variable is not set, or set to an empty string"
        exit 1
    fi

    # Download ZSH themes
    CURRENT_ZSH_THEME_DIR="$(dirname "$ZSH_THEME_PATH")"
    if [ -d "$CURRENT_ZSH_THEME_DIR" ]; then
        echo "Updating ZSH theme in: $CURRENT_ZSH_THEME_DIR"
        git -C "$CURRENT_ZSH_THEME_DIR" pull
    else
        echo "Downloading ZSH theme in: $CURRENT_ZSH_THEME_DIR"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$CURRENT_ZSH_THEME_DIR"
    fi

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

    if [ -z "$DEFAULT_SHELL" ]; then
        echo "The DEFAULT_SHELL variable is not set, or set to an empty string"
        exit 1
    fi

    if [ "$user_default_shell" != "$DEFAULT_SHELL" ]; then
        echo "Changing default shell to $DEFAULT_SHELL"
        sudo chsh -s "$DEFAULT_SHELL" "$TARGET_USER"
    fi

    unset font_dir
    unset user_default_shell
    echo "The default shell for $TARGET_USER is set to $DEFAULT_SHELL"
}

source_from_home_or_repo() {
    # The source_file_if_available function might not be available, so
    # source the functions file "manually".
    FILE_PATH_SUFFIX="${1}"
    FILE_PATH="${HOME}/${FILE_PATH_SUFFIX}"
    echo "Loading $FILE_PATH_SUFFIX from $FILE_PATH..."
    if ! [ -f "$FILE_PATH" ]; then
        # Get the absolute path to this script
        SCRIPT_PATH="$(readlink -f "$0")"
        SCRIPT_DIRECTORY="$(dirname "$SCRIPT_PATH")"
        # Go back one level to get the root of the repository
        FILE_PATH="${SCRIPT_DIRECTORY}/../${FILE_PATH_SUFFIX}"

        echo "Falling back to loading $FILE_PATH_SUFFIX from the git repository, in ${SCRIPT_DIRECTORY}."

        unset SCRIPT_PATH
    fi

    echo "Sourcing $FILE_PATH..."
    if [ -f "$FILE_PATH" ]; then
        # shellcheck source=/dev/null
        . "$FILE_PATH"
    else
        echo "ERROR: Cannot find the $FILE_PATH file."
        exit 1
    fi
    unset FILE_PATH
    unset FILE_PATH_SUFFIX
    unset SCRIPT_DIRECTORY
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

    get_user
    ask_for_sudo

    echo "Current working directory: $(pwd)"

    # The source_file_if_available function might not be available, so
    # sourcing it with a function in this script
    source_from_home_or_repo ".shells/.all/functions.sh"

    # Source the environment, because we it during setup
    source_from_home_or_repo ".shells/.all/environment.sh"

    if [[ $cmd == "debian" ]]; then
        setup_debian

        # Refresh the environment variables because there could be stale values,
        # after we installed packages, such as new shells.
        source_from_home_or_repo ".shells/.all/environment.sh"

        setup_shell
        setup_user
        update_system
        install_go_packages
        install_npm_packages
        install_python_packages
        install_rubygems
    elif [[ $cmd == "macos" ]]; then
        setup_macos
        install_brew
        install_brew_formulae
        setup_shell
        setup_user
        update_system
        install_go_packages
        install_npm_packages
        install_python_packages
        install_rubygems
    else
        usage
    fi
}

main "$@"
