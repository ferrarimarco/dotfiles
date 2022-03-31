#!/usr/bin/env sh

# Define this first, so sourcing other files becomes easier
source_file_if_available() {
  FILE="${1-}"
  VARIABLE_NAME="${2-}"

  if [ -z "${FILE}" ]; then
    echo "ERROR: Set a variable value when sourcing files. FILE: ${FILE}, VARIABLE_NAME: ${VARIABLE_NAME}"
    return 1
  fi

  if [ -f "${FILE}" ]; then
    # shellcheck source=/dev/null
    . "${FILE}"
  else
    echo "WARNING: Cannot source ${FILE}: it doesn't exist or it's not a file."
    return 2
  fi

  return 0
}

is_command_available() {
  if command -v "${1}" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

is_docker_available() {
  if is_command_available "docker" && [ -e /var/run/docker.sock ]; then
    return 0
  else
    return 1
  fi
}

if is_docker_available; then
  source_file_if_available "${DOCKERFUNCTIONS_PATH}" "DOCKERFUNCTIONS_PATH"
fi

is_snap_available() {
  if is_command_available "snap" && [ -e "/run/snapd.socket" ]; then
    return 0
  else
    return 1
  fi
}

# Create a new directory and enter it
mkd() {
  mkdir -p "$@"
  cd "$@" || exit
}

dump_defaults() {
  dir=
  if [ $# -eq 0 ]; then
    dir="$(pwd)"
  else
    dir="${1}"
  fi
  echo "Reading defaults..."
  defaults read NSGlobalDomain >"$dir"/NSGlobalDomain-before.out
  defaults read >"$dir"/read-before.out

  defaults read com.googlecode.iterm2 > "$dir"/iterm2-before.out

  defaults -currentHost read NSGlobalDomain >"$dir"/NSGlobalDomain-currentHost-before.out
  defaults -currentHost read >"$dir"/read-currentHost-before.out

  nvram -p > "$dir"/nvram-before.out

  echo "Change the settings, close the settings app, and press any key to continue..."
  read -r _
  unset _

  defaults read NSGlobalDomain >"$dir"/NSGlobalDomain-after.out
  defaults read >"$dir"/read-after.out

  defaults read com.googlecode.iterm2 > "$dir"/iterm2-after.out

  defaults -currentHost read NSGlobalDomain >"$dir"/NSGlobalDomain-currentHost-after.out
  defaults -currentHost read >"$dir"/read-currentHost-after.out

  nvram -p > "$dir"/nvram-after.out

  echo "Diffing..."
  diff "$dir"/NSGlobalDomain-before.out "$dir"/NSGlobalDomain-after.out
  diff "$dir"/NSGlobalDomain-currentHost-before.out "$dir"/NSGlobalDomain-currentHost-after.out
  diff "$dir"/read-currentHost-before.out "$dir"/read-currentHost-after.out
  diff "$dir"/read-before.out "$dir"/read-after.out
  diff "$dir"/nvram-before.out "$dir"/nvram-after.out
  diff "$dir"/iterm2-before.out "$dir"/iterm2-after.out

  echo "Inspect the output files if necessary, and press any key to continue..."
  read -r _
  unset _

  echo "Removing output files"
  rm \
    "$dir"/NSGlobalDomain-after.out \
    "$dir"/NSGlobalDomain-before.out \
    "$dir"/NSGlobalDomain-currentHost-after.out \
    "$dir"/NSGlobalDomain-currentHost-before.out \
    "$dir"/iterm2-before.out \
    "$dir"/iterm2-after.out \
    "$dir"/nvram-after.out \
    "$dir"/nvram-before.out \
    "$dir"/read-after.out \
    "$dir"/read-before.out \
    "$dir"/read-currentHost-after.out \
    "$dir"/read-currentHost-before.out
}

clone_git_repository_if_not_cloned_already() {
  destination_dir="$1"
  git_repository_url="$2"

  if [ -z "$destination_dir" ]; then
    echo "ERROR while cloning the $git_repository_url git repository: The destination_dir variable is not set, or set to an empty string"
    exit 1
  fi

  if [ -d "$destination_dir" ]; then
    echo "$destination_dir already exists. Skipping..."
  else
    mkdir -p "$destination_dir"
    echo "Cloning $git_repository_url in $destination_dir"
    git clone "$git_repository_url" "$destination_dir"
  fi
  unset destination_dir
  unset git_repository_url
}

create_python_venv() {
  destination_dir="$1"

  if [ -z "$destination_dir" ]; then
    echo "ERROR while creating the Python virtual environment in $destination_dir: The destination_dir variable is not set, or set to an empty string"
    return 1
  fi

  if [ -d "$destination_dir" ]; then
    echo "$destination_dir already exists. Skipping..."
  else
    echo "Creating a Python virtual environment in $destination_dir"
    python3 -m venv "$destination_dir"
  fi

  echo "You can activate the new environment by running: . $destination_dir/bin/activate"
}

is_apt_repo_available() {
  APT_REPOSITORY_URL="${1}"
  RET_CODE=

  if [ -z "$APT_REPOSITORY_URL" ]; then
    echo "ERROR: the APT_REPOSITORY_URL variable is not set, or set to an empty string"
    return 2
  fi
  if find /etc/apt/ -name '*.list' -exec grep -Fq "${APT_REPOSITORY_URL}" {} +; then
    RET_CODE=0
  else
    RET_CODE=1
  fi
  return $RET_CODE
}

is_linux() {
  # Set a default so that we don't have to rely on any environment variable being set
  OS_RELEASE_INFORMATION_FILE_PATH="/etc/os-release"
  if [ -e "${OS_RELEASE_INFORMATION_FILE_PATH}" ]; then
    # shellcheck source=/dev/null
    . "${OS_RELEASE_INFORMATION_FILE_PATH}"
    return 0
  elif is_command_available "uname"; then
    os_name="$(uname -s)"
    if [ "${os_name#*"Linux"}" != "$os_name" ]; then
      unset os_name
      return 0
    else
      unset os_name
      return 1
    fi
  else
    echo "Unable to determine if the OS is Linux."
    return 2
  fi
}

is_debian() {
  if is_linux && { [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; }; then
    return 0
  else
    return 1
  fi
}

is_codespaces() {
  if [ "${CODESPACES-}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

is_crostini() {
  if [ -d "/opt/google/cros-containers" ]; then
    return 0
  else
    return 1
  fi
}

is_ubuntu() {
  if is_debian && [ "${ID}" = "ubuntu" ]; then
    return 0
  else
    return 1
  fi
}

is_macos() {
  os_name="$(uname -s)"
  if test "${os_name#*"Darwin"}" != "$os_name"; then
    unset os_name
    return 0
  else
    unset os_name
    return 1
  fi
}

is_wsl() {
  VERSION_FILE_PATH=/proc/version
  if [ -f "$VERSION_FILE_PATH" ] && grep -q "Microsoft" "$VERSION_FILE_PATH"; then
    unset VERSION_FILE_PATH
    return 0
  else
    unset VERSION_FILE_PATH
    return 1
  fi
}

update_brew() {
  echo "Upgrading brew and formulae"
  brew update
  brew upgrade

  echo "Cleaning up brew..."
  brew cleanup -s

  echo "Checking for missing brew formula kegs..."
  brew missing
}

pull_from_git_repository() {
  destination_dir="$1"
  program_name="$2"
  if [ -d "$destination_dir/.git" ]; then
    echo "Updating $program_name in: $destination_dir"
    git -C "$destination_dir" pull
  else
    echo "WARNING: $destination_dir doesn't exists"
  fi
  unset destination_dir
  unset program_name
}

update_system() {
  if is_macos; then
    echo "Updating macOS..."
    sudo softwareupdate \
      --all \
      --install
    if command -v brew >/dev/null 2>&1; then
      update_brew
    fi
  elif is_debian; then
    echo "Updating linux..."
    sudo apt-get -q update
    sudo apt-get -qy upgrade
    pull_from_git_repository "$(dirname "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH")" "zsh-autosuggestions"
    pull_from_git_repository "$(dirname "$ZSH_COMPLETIONS_PATH")" "zsh-completions"

    if is_snap_available; then
      sudo snap refresh
    fi
  fi

  pull_from_git_repository "$(dirname "$ZSH_THEME_PATH")" "powerlevel10k"
}

# Make a temporary directory and enter it
tmpd() {
  dir=
  if [ $# -eq 0 ]; then
    dir=$(mktemp -d)
  else
    dir=$(mktemp -d -t "${1}.XXXXXXXXXX")
  fi
  cd "$dir" || exit
  unset dir
}

# Use Git’s colored diff when available
if is_command_available "git"; then
  diff() {
    git diff --no-index --color-words "$@"
  }
fi

# Get colors in manual pages
man() {
  env \
    LESS_TERMCAP_mb="$(printf '\e[1;31m')" \
    LESS_TERMCAP_md="$(printf '\e[1;31m')" \
    LESS_TERMCAP_me="$(printf '\e[0m')" \
    LESS_TERMCAP_se="$(printf '\e[0m')" \
    LESS_TERMCAP_so="$(printf '\e[1;44;33m')" \
    LESS_TERMCAP_ue="$(printf '\e[0m')" \
    LESS_TERMCAP_us="$(printf '\e[1;32m')" \
    man "$@"
}

uninstall_dotfiles() {
  echo "Uninstalling dotfiles..."
  find "${HOME}" -type l -ilname "*dotfiles*" -exec rm -fv {} \;

  if is_wsl; then
    sudo rm -fv /etc/wsl.conf
  fi
}

install_dotfiles() {
  SOURCE_PATH="${1}"
  if [ ! -d "${SOURCE_PATH}" ]; then
    echo "${SOURCE_PATH} doesn't exists."
    return 1
  fi

  echo "Setting up dotfiles from source directory: ${SOURCE_PATH}..."

  find "${SOURCE_PATH}" -type f -path "*/\.*" -not -name ".gitignore" -not -path "*/\.github/*" -not -path "*/\.git/*" -not -name ".*.swp" >tmp
  while IFS= read -r file; do
    # Strip the ${SOURCE_PATH} prefix from the file path
    file_base_path="${file##"${SOURCE_PATH}/"}"
    file_path="${HOME}/${file_base_path}"
    echo "File to link: ${file}. File base path: ${file_base_path}. Target file path: ${file_path}"
    mkdir -pv "$(dirname "$file_path")"

    if [ -f "${file_path}" ]; then
      echo "${file_path} already exists and it's a regular file, not a symbolic link. Details:"
      ls -alh "${file_path}"

      BACKUP_FILE_PATH="${file_path}.backup"
      echo "Moving ${file_path} to ${BACKUP_FILE_PATH}..."
      mv "${file_path}" "${BACKUP_FILE_PATH}"
    fi

    ln -sfnv "${file}" "${file_path}"
  done <tmp
  rm tmp

  ln -sfnv "${SOURCE_PATH}/gitignore" "${HOME}/.gitignore"

  WSL_CONFIGURATION_FILE_PATH="/etc/wsl.conf"
  if is_wsl && [ -e "${WSL_CONFIGURATION_FILE_PATH}" ]; then
    sudo cp -fv "${HOME}/.config/wsl/wsl.conf" "${WSL_CONFIGURATION_FILE_PATH}"
  fi
  unset WSL_CONFIGURATION_FILE_PATH
  unset SOURCE_PATH
}
