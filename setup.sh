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
    if ! xcode-select -p >/dev/null 2>&1; then
      echo "Installing Xcode CLI..."
      xcode-select --install
    else
      echo "Xcode is already installed"
    fi

    echo "Installing Homebrew to: ${HOMEBREW_PATH}"
    # Homebrew installation script asks for confirmation before running any action
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

  echo "Running brew cleanup..."
  brew cleanup

  echo "Installing brew formulae"
  for f in \
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
    visual-studio-code; do
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
}

setup_user() {
  echo "Creating directories for the $TARGET_USER in $HOME"
  mkdir -pv "$HOME/.terraform.d"
  mkdir -pv "$HOME/bin"
  mkdir -pv "$HOME/Downloads"
  mkdir -pv "$HOME/workspaces-work"
  mkdir -pv "$HOME/workspaces"

  mkdir -pv "${GCLOUD_CONFIG_DIRECTORY}"
  mkdir -pv "${USER_CACHE_DIRECTORY}"

  touch "$HOME/.gitconfig-work"
}

setup_debian() {
  echo "Setting up a Debian or Debian-based system"

  DEBIAN_FRONTEND=noninteractive
  export DEBIAN_FRONTEND

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
  fi

  DISTRIBUTION="$(lsb_release -ds)"
  DISTRIBUTION_CODENAME="$(lsb_release -cs)"
  echo "Configuring the distribution: ${DISTRIBUTION}, codename: ${DISTRIBUTION_CODENAME}..."

  docker_apt_repository_url=

  docker_distribution=

  if is_official_debian || is_ubuntu; then

    docker_distribution="debian"

    echo "Enabling main repository"
    sudo add-apt-repository --yes main

    if is_ubuntu; then
      echo "Enabling universe, multiverse, and restricted repositories"
      sudo add-apt-repository --yes universe
      sudo add-apt-repository --yes multiverse
      sudo add-apt-repository --yes restricted
      docker_distribution="ubuntu"
    fi

    docker_apt_repository_url="https://download.docker.com/linux/${docker_distribution}"
    if ! is_apt_repo_available "${docker_apt_repository_url}"; then
      add_apt_repo \
        "${docker_apt_repository_url}/gpg" \
        "docker.gpg" \
        "${docker_apt_repository_url}" \
        "docker.list"
    fi

    vs_code_apt_repository_url="https://packages.microsoft.com/repos/code"
    if ! is_apt_repo_available "${vs_code_apt_repository_url}"; then
      add_apt_repo \
        "https://packages.microsoft.com/keys/microsoft.asc" \
        "packages.microsoft.gpg" \
        "${vs_code_apt_repository_url}" \
        "vscode.list" \
        "stable main"
    fi
    unset vs_code_apt_repository_url
  elif is_debian && ! is_official_debian; then
    echo "This is a non-official Debian distribution."
  else
    echo "WARNING: distribution ${DISTRIBUTION} is not supported. Skipping distribution-specific configuration..."
  fi

  clone_git_repository_if_not_cloned_already "$(dirname "${ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH}")" "https://github.com/zsh-users/zsh-autosuggestions.git"
  clone_git_repository_if_not_cloned_already "$(dirname "${ZSH_COMPLETIONS_PATH}")" "https://github.com/zsh-users/zsh-completions.git"

  sudo apt-get -qq update

  sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
    bash-completion \
    bridge-utils \
    bzip2 \
    coreutils \
    dnsutils \
    file \
    findutils \
    grep \
    gzip \
    hostname \
    less \
    locales \
    lsof \
    mount \
    nano \
    net-tools \
    python3-pip \
    python3-venv \
    tree \
    unzip \
    xclip \
    xz-utils \
    zip \
    zsh \
    zsh-syntax-highlighting \
    --no-install-recommends

  if is_official_debian || is_ubuntu; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
      code
  fi

  if is_codespaces; then
    # Workaround for https://github.com/microsoft/WSL/issues/2775
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy remove \
      azure-cli
  fi

  echo "Installing packages from the additional APT repositories..."
  # Don't use docker_apt_repository_url so this check works on distributions that
  # don't use the standard Docker APT repository
  if is_apt_repo_available "docker"; then
    echo "Installing Docker..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
      containerd.io \
      docker-ce \
      docker-ce-cli

    if is_official_debian || is_ubuntu; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
        docker-buildx-plugin \
        docker-compose-plugin
    else
      echo "Setting Docker Buildx as the default builder using the legacy installation method..."
      sudo docker buildx install

      echo "Install Docker Compose using the legacy installation method"
      sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy install \
        docker-compose
    fi

    DOCKER_GROUP_NAME="docker"
    echo "Creating the $DOCKER_GROUP_NAME group for Docker"
    getent group "$DOCKER_GROUP_NAME" >/dev/null 2>&1 || sudo groupadd "$DOCKER_GROUP_NAME"
    echo "Adding $TARGET_USER user to the $DOCKER_GROUP_NAME group"
    sudo gpasswd -a "$TARGET_USER" "$DOCKER_GROUP_NAME"
    unset DOCKER_GROUP_NAME
  else
    echo "WARNING: Skipping Docker installation because its APT repository is not available"
  fi

  unset docker_apt_repository_url

  sudo apt-get -qqy autoremove
  sudo apt-get -qqy autoclean
  sudo apt-get -qqy clean

  if [ -z "$TARGET_USER" ]; then
    echo "ERROR: The TARGET_USER variable is not set, or set to an empty string"
    exit 1
  fi

  echo "Adding $TARGET_USER user to the sudoers group"
  sudo gpasswd -a "$TARGET_USER" sudo
}

setup_macos() {
  echo "Setting up macOS"

  ###############################################################################
  # General UI/UX                                                               #
  ###############################################################################

  echo "Configuring macOS UI/UX"

  # Disable the sound effects on boot
  sudo nvram SystemAudioVolume=%00

  # Enable the sound effects on boot
  # sudo nvram SystemAudioVolume=%01

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

  # Disable lookup and data detectors
  defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false

  # Trackpad: enable tap to click for this user
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Trackpad: enable tap to click for the login screen
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  ###############################################################################
  # Keyboard                                                                    #
  ###############################################################################

  # Keyboard: enable press-and-hold popup to write accented characters
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true

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

  if is_ci; then
    # Workaround for https://github.com/actions/runner-images/issues/6817
    if is_command_available "2to3"; then
      rm -fv "$(command -v 2to3)"
    fi
  fi

  ###############################################################################
  # Kill affected applications                                                  #
  ###############################################################################

  echo "Killing and restarting affected apps"

  for app in "Activity Monitor" \
    "cfprefsd" \
    "Dock" \
    "Finder" \
    "SystemUIServer"; do
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
  mkdir -pv "${USER_FONTS_DIRECTORY}"
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Regular.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Italic.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
  ! [ -e "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold Italic.ttf" ] && curl -fsLo "${USER_FONTS_DIRECTORY}/MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

  if is_default_shell_zsh; then
    echo "Configuring ZSH"
    mkdir -pv "${ZSH_CACHE_DIR}"
  fi

  echo "Shell configuration completed."
}

set_repository_path() {
  SCRIPT_PATH="$0"
  echo "The path to this script is: $SCRIPT_PATH. Checking if it's a link and following it..."

  CURRENT_WORKING_DIRECTORY="$(pwd)"
  echo "The current working directory is $CURRENT_WORKING_DIRECTORY"

  # Cannot use the is_XXXX or other functions defined in functions.sh because they might not be available at this point
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

main() {
  get_user
  ask_for_sudo

  echo "Current working directory: $(pwd)"
  echo "Current home directory: ${HOME}"

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

  echo "Sourcing ${FUNCTIONS_FILE_ABSOLUTE_PATH}..."
  if [ -f "${FUNCTIONS_FILE_ABSOLUTE_PATH}" ]; then
    # shellcheck source=/dev/null
    . "${FUNCTIONS_FILE_ABSOLUTE_PATH}"
  else
    echo "ERROR: Cannot find the ${FUNCTIONS_FILE_ABSOLUTE_PATH} file. Exiting..."
    exit 1
  fi
  # From now on, the source_file_if_available function is available

  ENVIRONMENT_FILE_ABSOLUTE_PATH="$REPOSITORY_PATH/.shells/.all/environment.sh"
  echo "Sourcing environment variables configuration file from ${ENVIRONMENT_FILE_ABSOLUTE_PATH}..."
  source_file_if_available "${ENVIRONMENT_FILE_ABSOLUTE_PATH}" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

  if is_linux || is_macos; then
    if is_debian; then
      setup_debian
    elif is_macos; then
      setup_macos
      install_brew
    fi

    echo "Refresh the environment variables from $ENVIRONMENT_FILE_ABSOLUTE_PATH because there could be stale values."
    source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

    if is_macos; then
      install_brew_formulae

      echo "Refresh the environment variables from $ENVIRONMENT_FILE_ABSOLUTE_PATH because there could be stale values."
      source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"
    fi

    setup_shell
    setup_user
    install_dotfiles "${REPOSITORY_PATH}"
    install_vs_code_extensions
    update_dotfiles
  else
    echo "The current OS or distribution is not supported. Terminating..."
    exit 1
  fi
}

main
