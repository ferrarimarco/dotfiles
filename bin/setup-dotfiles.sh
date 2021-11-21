#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ask_for_sudo() {
  echo "Prompting for sudo password..."
  # sudo -v doesn't work on macOS when passwordless sudo is enabled. It still
  # asks for a password. sudo true should work for both Linux and macOS
  if sudo true; then
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

fix_permissions() {
  echo "Setting home directory ($HOME) permissions..."
  # Cannot use chmod recursive mode because system integrity protection prevents
  # changing some attributes of $HOME/Library directories on macOS
  find "$HOME" -type d -path "$HOME"/Library -prune -o -exec chmod o-rwx {} \;
}

# Choose a user account to use for this installation
get_user() {
  echo "Setting TARGET_USER. The order of preference is: USER (${USER-}), USERNAME (${USERNAME-}), LOGNAME (${LOGNAME-}), whoami ($(whoami))"
  TARGET_USER="${USER:-${USERNAME:-${LOGNAME:-$(whoami)}}}"
  echo "TARGET_USER set to: $TARGET_USER"

  if [ -z "$TARGET_USER" ]; then
    echo "ERROR: The TARGET_USER variable is not set, or set to an empty string"
    exit 1
  fi
}

install_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    # Set xcode directory
    XCODE_DIRECTORY=/Applications/Xcode.app/Contents/Developer
    echo "Setting Xcode directory to $XCODE_DIRECTORY..."
    sudo xcode-select -s "$XCODE_DIRECTORY"
    unset XCODE_DIRECTORY

    echo "Accepting Xcode license..."
    sudo xcodebuild -license accept

    if ! xcode-select -p >/dev/null 2>&1; then
      echo "Installing Xcode CLI..."
      xcode-select --install
    else
      echo "Xcode is already installed"
    fi

    echo "Initializing Homebrew repository path (${HOMEBREW_REPOSITORY}) and Homebrew path (${HOMEBREW_PATH})..."
    HOMEBREW_BIN_PATH="${HOMEBREW_PATH}"/bin
    sudo install -d -o "$TARGET_USER" "${HOMEBREW_PATH}" "${HOMEBREW_BIN_PATH}" "${HOMEBREW_PATH}"/sbin "${HOMEBREW_REPOSITORY}"

    # Download and install Homebrew
    echo "Installing Homebrew..."
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
}

install_brew_formulae() {
  echo "Installing brew formulae..."

  if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: the brew command is not available. Exiting..."
    exit 1
  fi

  echo "Disabling homebrew usage analytics..."
  brew analytics off

  echo "Removing installed brew formulae..."
  # shellcheck disable=SC2046
  brew uninstall --force --ignore-dependencies $(brew list --formula)

  echo "Removing installed brew casks..."
  # shellcheck disable=SC2046
  brew uninstall --force --zap $(brew list --cask)

  echo "Running brew cleanup..."
  brew cleanup

  echo "Installing brew formulae"
  for f in \
    make \
    zsh-autosuggestions \
    zsh-completions \
    zsh-syntax-highlighting; do
    if ! brew list --versions "$f" >/dev/null; then
      echo "Installing $f"
      if ! brew install "$f"; then
        # If the installation failed, retry with verbose output enabled.
        # Useful for CI builds.
        brew install --verbose "$f"
      fi
    else
      echo "$f is already installed"
    fi
  done

  # Other useful casks that I might need in the future:
  # docker, gimp

  echo "Installing brew casks..."
  for f in \
    iterm2 \
    visual-studio-code \
    wireshark; do
    if ! brew list "$f" >/dev/null 2>&1; then
      echo "Installing $f cask"
      if ! brew install "$f"; then
        # If the installation failed, retry with verbose output enabled.
        # Useful for CI builds.
        brew install --verbose "$f"
      fi
    else
      echo "$f cask is already installed"
    fi
  done

  # Save Homebrew’s installed location.
  BREW_PREFIX="$(brew --prefix)"

  if [ -z "$BREW_PREFIX" ]; then
    echo "ERROR: The BREW_PREFIX variable is not set, or set to an empty string"
    exit 1
  fi

  echo "Setting up Visual Studio Code settings..."
  _vs_code_settings_path="$HOME"/Library/Application\ Support/Code/User/settings.json
  echo "Ensuring that the Visual Studio Code settings directory ($_vs_code_settings_path) is available..."
  mkdir -p "$(dirname "$_vs_code_settings_path")"
  VS_CODE_SETTINGS_FILE_PATH="$HOME"/.config/Code/User/settings.json
  echo "Creating a symbolic link from $VS_CODE_SETTINGS_FILE_PATH to $_vs_code_settings_path"
  ln -sfn "$VS_CODE_SETTINGS_FILE_PATH" "$_vs_code_settings_path"
  unset _vs_code_settings_path
  unset VS_CODE_SETTINGS_FILE_PATH

  echo "Installing or updating Visual Studio Code extensions..."
  while IFS= read -r line; do
    echo "Installing or updating $line extension..."
    code --force --install-extension "$line"
  done <"$REPOSITORY_PATH"/.config/ferrarimarco-dotfiles/vs-code/extensions.txt
}

setup_user() {
  echo "Creating directories for the $TARGET_USER in $HOME"
  mkdir -p "$HOME/Downloads"
  mkdir -p "$HOME/workspaces"

  mkdir -p "${GCLOUD_CONFIG_DIRECTORY}"
}

setup_debian() {
  echo "Setting up a Debian system"

  echo "Installing the minimal set of packages"
  sudo apt-get -qq update || true
  sudo apt-get -qqy install \
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
    sudo \
    --no-install-recommends

  echo "Ensuring the $LANG locale is available..."
  sudo locale-gen "$LANG"
  sudo dpkg-reconfigure --frontend=noninteractive locales
  sudo update-locale LANG="$LANG" LANGUAGE="$LANGUAGE" LC_ALL="$LC_ALL"

  # Add the Google Chrome distribution URI as a package source if needed
  # Don't install it if we're in crostini (Chrome OS linux environment) or if it's already installed
  if ! is_crostini && ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
    echo "Installing Chrome browser..."

    echo "Downloading Chrome package..."
    TEMP_DIRECTORY="$(mktemp -d)"
    CHROME_ARCHIVE_NAME=google-chrome-stable_current_amd64.deb
    CHROME_ARCHIVE_PATH="$TEMP_DIRECTORY/$CHROME_ARCHIVE_NAME"
    curl -fsLo "$CHROME_ARCHIVE_PATH" https://dl.google.com/linux/direct/"$CHROME_ARCHIVE_NAME"

    echo "Making the temporary directory world-accessible..."
    chmod -Rv 777 "$TEMP_DIRECTORY"

    echo "Installing Chrome package..."
    sudo apt-get -qqy install "$CHROME_ARCHIVE_PATH"

    echo "Removing Chrome package..."
    rm "$CHROME_ARCHIVE_PATH"

    echo "Removing the temporary directory..."
    rm -rf "$TEMP_DIRECTORY"

    echo "Installing missing dependencies..."
    sudo apt-get -fqq install

    unset TEMP_DIRECTORY
    unset CHROME_ARCHIVE_NAME
    unset CHROME_ARCHIVE_PATH
  else
    echo "Google Chrome is already installed"
  fi

  DISTRIBUTION="$(lsb_release -ds)"
  DISTRIBUTION_CODENAME="$(lsb_release -cs)"
  echo "Configuring the distribution: ${DISTRIBUTION}, codename: ${DISTRIBUTION_CODENAME}..."

  docker_apt_repository_url=

  docker_distribution=

  if is_debian || is_ubuntu; then
    sudo add-apt-repository main
    if is_debian; then
      docker_distribution="debian"
    elif is_ubuntu; then
      sudo add-apt-repository universe
      sudo add-apt-repository multiverse
      sudo add-apt-repository restricted
      docker_distribution="ubuntu"
    fi

    docker_apt_repository_url="https://download.docker.com/linux/${docker_distribution}"
    if ! is_apt_repo_available "${docker_apt_repository_url}"; then
      echo "Adding Docker APT repository"
      curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] ${docker_apt_repository_url} ${DISTRIBUTION_CODENAME} stable"
    fi
  else
    echo "WARNING: distribution ${DISTRIBUTION} is not supported. Skipping distribution-specific configuration..."
  fi

  clone_git_repository_if_not_cloned_already "$(dirname "$ZSH_COMPLETIONS_PATH")" "https://github.com/zsh-users/zsh-completions.git"

  sudo apt-get -qq update || true

  sudo apt-get -qqy install \
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
    iptables \
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
    python3-venv \
    rxvt-unicode \
    scdaemon \
    socat \
    snapd \
    ssh \
    strace \
    systemd \
    tar \
    tree \
    tzdata \
    unzip \
    vlc \
    xclip \
    xcompmgr \
    xz-utils \
    zip \
    zlib1g-dev \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    --no-install-recommends

  echo "Ensure snapd is running..."
  sudo systemctl enable snapd.service
  sudo systemctl start snapd.service

  echo "Upgrading snapd..."
  sudo snap install core

  echo "Installing packages from the additional APT repositories..."
  if is_apt_repo_available "${docker_apt_repository_url}"; then
    echo "Installing Docker..."
    sudo apt-get -qqy install \
      containerd.io \
      docker-ce \
      docker-ce-cli
  else
    echo "WARNING: Skipping Docker installation because its APT repository is not available"
  fi

  sudo apt-get -qqy autoremove
  sudo apt-get -qqy autoclean
  sudo apt-get -qqy clean

  DOCKER_GROUP_NAME="docker"
  echo "Creating the $DOCKER_GROUP_NAME group for Docker"
  getent group "$DOCKER_GROUP_NAME" >/dev/null 2>&1 || sudo groupadd "$DOCKER_GROUP_NAME"
  unset DOCKER_GROUP_NAME

  if [ -z "$TARGET_USER" ]; then
    echo "ERROR: The TARGET_USER variable is not set, or set to an empty string"
    exit 1
  fi

  echo "Adding $TARGET_USER user to the sudoers group"
  sudo gpasswd -a "$TARGET_USER" sudo

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

  # Don't move the dock to secondary screens
  defaults write com.apple.Dock position-immutable -bool yes

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
  # Touch bar                                                                    #
  ###############################################################################
  defaults write com.apple.controlstrip MiniCustomized "(com.apple.system.brightness, com.apple.system.volume, com.apple.system.mute)"

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

  clone_git_repository_if_not_cloned_already "$(dirname "$ZSH_THEME_PATH")" "https://github.com/romkatv/powerlevel10k.git"

  user_default_shell=
  if is_macos; then
    user_default_shell="$(dscl . -read ~/ UserShell | sed 's/UserShell: //')"
  elif is_linux; then
    user_default_shell="$(awk -F: -v user="${TARGET_USER}" '$1 == user {print $NF}' /etc/passwd)"
    if [ -z "${user_default_shell}" ]; then
      user_default_shell="$(getent passwd "${TARGET_USER}" | awk -F: -v user="${TARGET_USER}" '$1 == user {print $NF}')"
    fi
  fi

  if [ -z "$DEFAULT_SHELL" ]; then
    echo "ERROR: The DEFAULT_SHELL variable is not set, or set to an empty string"
    exit 1
  fi

  if [ -z "${user_default_shell}" ]; then
    echo "ERROR: The user_default_shell variable is not set, or set to an empty string"
    exit 1
  fi

  if [ "${user_default_shell}" != "$DEFAULT_SHELL" ]; then
    echo "Changing default shell from ${user_default_shell} to $DEFAULT_SHELL"
    sudo chsh -s "$DEFAULT_SHELL" "$TARGET_USER"
  fi

  unset user_default_shell
  echo "The default shell for $TARGET_USER is set to $DEFAULT_SHELL"

  if [ -z "$USER_FONTS_DIRECTORY" ]; then
    echo "ERROR: The USER_FONTS_DIRECTORY variable is not set, or set to an empty string"
    exit 1
  fi

  echo "Downloading fonts in ${USER_FONTS_DIRECTORY}"
  mkdir -p "${USER_FONTS_DIRECTORY}"
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Regular.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Italic.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold Italic.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

  echo "Shell configuration completed."
}

set_repository_path() {
  SCRIPT_PATH="$0"
  echo "The path to this script is: $SCRIPT_PATH. Checking if it's a link and following it..."

  CURRENT_WORKING_DIRECTORY="$(pwd)"
  echo "The current working directory is $CURRENT_WORKING_DIRECTORY"

  # Cannot use the is_XXXX functions here because they might not be available at this point
  os_name="$(uname -s)"
  if test "${os_name#*"Darwin"}" != "$os_name"; then
    DIR="$(dirname "$SCRIPT_PATH")"
    echo "Changing directory to $DIR..."
    cd "$DIR"
    TARGET_FILE="$(basename "$SCRIPT_PATH")"

    echo "Checking if $TARGET_FILE is a link..."
    # Iterate down a (possible) chain of symlinks
    while [ -L "$TARGET_FILE" ]; do
      LINK_TARGET="$(readlink "$TARGET_FILE")"
      echo "$TARGET_FILE is a link to $LINK_TARGET. Following the link..."

      TARGET_FILE="$LINK_TARGET"
      DIR="$(dirname "$TARGET_FILE")"
      echo "Changing directory to $DIR..."
      cd "$DIR"
      TARGET_FILE="$(basename "$TARGET_FILE")"
      echo "Checking if $TARGET_FILE is a link..."
    done

    unset DIR
    unset LINK_TARGET

    echo "$TARGET_FILE is not a link. Reached the end of the chain."

    # Compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    PHYS_DIR="$(pwd -P)"
    echo "The current working directory is: $PHYS_DIR. Using it to build the absolute path to $SCRIPT_PATH"
    ABSOLUTE_SCRIPT_PATH="$PHYS_DIR/$TARGET_FILE"

    unset TARGET_FILE
  elif test "${os_name#*"Linux"}" != "$os_name"; then
    # Use readlink -f directly
    ABSOLUTE_SCRIPT_PATH="$(readlink -f "$0")"
  fi
  unset os_name

  echo "The absolute path to this script is: $ABSOLUTE_SCRIPT_PATH. Using it to build the absolute path to the repository directory..."
  SCRIPT_DIRECTORY="$(dirname "$ABSOLUTE_SCRIPT_PATH")"
  unset ABSOLUTE_SCRIPT_PATH
  echo "The script directory is: $SCRIPT_DIRECTORY. Using it to set the working directory for git..."

  # This is a git repository, so use this fact to get the root of the repository
  REPOSITORY_PATH="$(git -C "$SCRIPT_DIRECTORY" rev-parse --show-toplevel)"
  unset SCRIPT_DIRECTORY
  echo "The repository path is: $REPOSITORY_PATH"

  echo "Going back to the previous working directory: $CURRENT_WORKING_DIRECTORY"
  cd "$CURRENT_WORKING_DIRECTORY"
  unset CURRENT_WORKING_DIRECTORY
}

SCRIPT_BASENAME="$(basename "${0}")"

usage() {
  echo -e "${SCRIPT_BASENAME}\\n\\tThis script installs my basic setup for a workstation\\n"
  echo "Usage:"
  echo "  debian                              - install base packages on a Debian system"
  echo "  macos                               - setup macOS"
}

main() {
  local cmd="${1-}"

  if [[ -z "$cmd" ]]; then
    usage
    exit 1
  fi

  get_user
  ask_for_sudo

  echo "Current working directory: $(pwd)"

  echo "Setting the REPOSITORY_PATH variable..."
  set_repository_path
  if [ -z "$REPOSITORY_PATH" ]; then
    echo "ERROR: The REPOSITORY_PATH variable is empty or not set. Exiting..."
    exit 1
  fi
  echo "Path to the repository: $REPOSITORY_PATH"

  # The source_file_if_available function might not be available, so
  # sourcing the functions files it explicitly
  FUNCTIONS_FILE_ABSOLUTE_PATH="${REPOSITORY_PATH}/.shells/.all/functions.sh"

  # Set the DOCKERFUNCTIONS_PATH because it's not yet available in the default location set in environment.sh
  DOCKERFUNCTIONS_PATH="${REPOSITORY_PATH}"/.shells/.all/dockerfunctions.sh
  export DOCKERFUNCTIONS_PATH

  echo "Sourcing $FUNCTIONS_FILE_ABSOLUTE_PATH..."
  if [ -f "${FUNCTIONS_FILE_ABSOLUTE_PATH}" ]; then
    # shellcheck source=/dev/null
    . "${FUNCTIONS_FILE_ABSOLUTE_PATH}"
  else
    echo "ERROR: Cannot find the $FUNCTIONS_FILE_ABSOLUTE_PATH file. Exiting..."
    exit 1
  fi
  # From now on, the source_file_if_available function is available

  ENVIRONMENT_FILE_ABSOLUTE_PATH="$REPOSITORY_PATH/.shells/.all/environment.sh"
  echo "Sourcing environment variables configuration file from ${ENVIRONMENT_FILE_ABSOLUTE_PATH}..."
  source_file_if_available "${ENVIRONMENT_FILE_ABSOLUTE_PATH}" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

  if [[ $cmd == "debian" ]]; then
    setup_debian

    echo "Refresh the environment variables from $ENVIRONMENT_FILE_ABSOLUTE_PATH because there could be stale values, after we installed packages, such as new shells."
    source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

    setup_shell
    setup_user
    update_system
    fix_permissions
  elif [[ $cmd == "macos" ]]; then
    setup_macos
    install_brew

    echo "Refresh the environment variables from $ENVIRONMENT_FILE_ABSOLUTE_PATH because there could be stale values, after we installed packages, such as new shells."
    source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

    install_brew_formulae

    echo "Refresh the environment variables from $ENVIRONMENT_FILE_ABSOLUTE_PATH because there could be stale values, after we installed packages, such as new shells."
    source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

    setup_shell
    setup_user
    update_system
  else
    usage
  fi
}

main "$@"
