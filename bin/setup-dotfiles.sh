#!/usr/bin/env bash

set -e
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
  echo "Setting TARGET_USER. The order of preference is: USER ($USER), USERNAME ($USERNAME), LOGNAME ($LOGNAME), whoami ($(whoami))"
  TARGET_USER=${USER:-${USERNAME:-${LOGNAME:-$(whoami)}}}
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
  brew remove --force --ignore-dependencies $(brew list)

  echo "Removing installed brew casks..."
  # shellcheck disable=SC2046
  brew cask remove --force $(brew list --cask)

  echo "Running brew cleanup..."
  brew cleanup

  for f in \
    ccache \
    cmake \
    coreutils \
    dfu-util \
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
    ninja \
    p7zip \
    tree \
    wget \
    zsh \
    zsh-autosuggestions \
    zsh-completions \
    zsh-syntax-highlighting; do
    if ! brew ls --versions "$f" >/dev/null; then
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

  echo "Installing brew casks..."
  for f in \
    docker \
    gimp \
    iterm2 \
    visual-studio-code; do
    if ! brew cask ls --versions "$f" >/dev/null 2>&1; then
      echo "Installing $f cask"
      if ! brew cask install "$f"; then
        # If the installation failed, retry with verbose output enabled.
        # Useful for CI builds.
        brew cask install --verbose "$f"
      fi
    else
      echo "$f cask is already installed"
    fi
  done

  echo "Adding shells installed via brew to the list of allowed shells..."

  # Save Homebrew’s installed location.
  BREW_PREFIX="$(brew --prefix)"

  if [ -z "$BREW_PREFIX" ]; then
    echo "ERROR: The BREW_PREFIX variable is not set, or set to an empty string"
    exit 1
  fi

  if ! grep -Fq "${BREW_PREFIX}/bin/bash" /etc/shells; then
    echo "Add bash installed via brew to the list of allowed shells..."
    echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
  else
    echo "Bash installed via brew is already in the list of allowed shells."
  fi

  if ! grep -Fq "${BREW_PREFIX}/bin/zsh" /etc/shells; then
    echo "Add zsh installed via brew to the list of allowed shells..."
    echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells
  else
    echo "zsh installed via brew is already in the list of allowed shells."
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
  mkdir -p "$HOME/Pictures/Screenshots"
  mkdir -p "$HOME/Pictures/Wallpapers"
  mkdir -p "$HOME/workspaces"
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

    unset docker_distribution
  fi

  clone_git_repository_if_not_cloned_already "$(dirname "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH")" "https://github.com/zsh-users/zsh-autosuggestions.git"
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
    containerd.io \
    coreutils \
    docker-ce \
    docker-ce-cli \
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
    ssh \
    strace \
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
    zsh-syntax-highlighting \
    --no-install-recommends

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
  defaults write com.apple.controlstrip MiniCustomized "(com.apple.system.brightness, com.apple.system.volume, com.apple.system.mute, com.apple.system.media-play-pause, com.apple.system.screen-lock)"

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
    user_default_shell="$(awk -F: -v user="$USER" '$1 == user {print $NF}' /etc/passwd)"
  fi

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

  if [ -z "$DEFAULT_SHELL" ]; then
    echo "ERROR: The DEFAULT_SHELL variable is not set, or set to an empty string"
    exit 1
  fi

  if [ "$user_default_shell" != "$DEFAULT_SHELL" ]; then
    echo "Changing default shell to $DEFAULT_SHELL"
    sudo chsh -s "$DEFAULT_SHELL" "$TARGET_USER"
  fi

  unset user_default_shell
  echo "The default shell for $TARGET_USER is set to $DEFAULT_SHELL"
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

  echo "Setting the REPOSITORY_PATH variable..."
  set_repository_path
  if [ -z "$REPOSITORY_PATH" ]; then
    echo "ERROR: The REPOSITORY_PATH variable is empty or not set. Exiting..."
    exit 1
  fi
  echo "Path to the repository: $REPOSITORY_PATH"

  # The source_file_if_available function might not be available, so
  # sourcing the functions file it explicitly
  FUNCTIONS_FILE_ABSOLUTE_PATH="$REPOSITORY_PATH/.shells/.all/functions.sh"
  echo "Sourcing $FUNCTIONS_FILE_ABSOLUTE_PATH..."
  if [ -f "$FUNCTIONS_FILE_ABSOLUTE_PATH" ]; then
    # shellcheck source=/dev/null
    . "$FUNCTIONS_FILE_ABSOLUTE_PATH"
  else
    echo "ERROR: Cannot find the $FUNCTIONS_FILE_ABSOLUTE_PATH file. Exiting..."
    exit 1
  fi
  # From now on, the source_file_if_available function is available

  ENVIRONMENT_FILE_ABSOLUTE_PATH="$REPOSITORY_PATH/.shells/.all/environment.sh"
  echo "Sourcing environment variables configuration file..."
  source_file_if_available "$ENVIRONMENT_FILE_ABSOLUTE_PATH" "ENVIRONMENT_FILE_ABSOLUTE_PATH"

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
