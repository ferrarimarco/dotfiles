#!/usr/bin/env sh

# Create a new directory and enter it
mkd() {
    mkdir -p "$@"
    cd "$@" || exit
}

add_ssh_known_hosts() {
    SSH_KNOWN_HOSTS_PATH="$HOME"/.ssh/known_hosts
    echo "Adding ${1} to known SSH hosts ($SSH_KNOWN_HOSTS_PATH)."
    ssh-keyscan "${1}" >>"$SSH_KNOWN_HOSTS_PATH"
    unset SSH_KNOWN_HOSTS_PATH
}

# If you install brew formulae from source, you may want to install its
# deps from source as well
brew_install_recursive_build_from_source() {
    echo "Installing $* and it's deps from source"
    brew deps --include-build --include-optional -n "$@" | while read -r line; do
        brew install --build-from-source "$line"
    done
    brew install --build-from-source "$@"
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
    defaults -currentHost read NSGlobalDomain >"$dir"/NSGlobalDomain-currentHost-before.out
    defaults read >"$dir"/read-before.out
    defaults -currentHost read >"$dir"/read-currentHost-before.out

    echo "Change the settings and press any key to continue..."
    read -r _
    unset _

    defaults read NSGlobalDomain >"$dir"/NSGlobalDomain-after.out
    defaults -currentHost read NSGlobalDomain >"$dir"/NSGlobalDomain-currentHost-after.out
    defaults read >"$dir"/read-after.out
    defaults -currentHost read >"$dir"/read-currentHost-after.out

    echo "Diffing..."
    diff "$dir"/NSGlobalDomain-before.out "$dir"/NSGlobalDomain-after.out
    diff "$dir"/NSGlobalDomain-currentHost-before.out "$dir"/NSGlobalDomain-currentHost-after.out
    diff "$dir"/read-currentHost-before.out "$dir"/read-currentHost-after.out
}

check_eof_newline() {
    dir=
    if [ $# -eq 0 ]; then
        dir="$(pwd)"
    else
        dir="${1}"
    fi

    find "$dir" -type f -not -path "*/\.git/*" >tmp
    while IFS= read -r file; do
        if [ -z "$(tail -c1 "$file")" ]; then
            echo "[OK]: $file ends with a newline"
        else
            echo "[FAIL]: missing newline at the end of $file"
        fi
    done <tmp
    rm tmp
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

# find all scripts and run `shfmt`
shfmt_dir() {
    dir=
    if [ $# -eq 0 ]; then
        dir="$(pwd)"
    else
        dir="${1}"
    fi
    find "$dir" -type f -not -path "*/\\.git/*" | sort -u | while read -r f; do
        if grep -Eq '^#!(.*/|.*env +)(sh|bash|ksh|mksh)' "$f"; then
            if shfmt -d "$f"; then
                echo "shfmt on $f PASSED"
            else
                echo "shfmt on $f FAILED"
            fi
        fi
    done
    unset dir
}

# find all scripts and run `shellcheck`
shellcheck_dir() {
    dir=
    if [ $# -eq 0 ]; then
        dir="$(pwd)"
    else
        dir="${1}"
    fi
    find "$dir" -type f -not -path "*/\\.git/*" | sort -u | while read -r f; do
        if grep -Eq '^#!(.*/|.*env +)(sh|bash|ksh|mksh)' "$f"; then
            if shellcheck "$f"; then
                echo "[OK]: sucessfully linted $f"
            else
                echo "[FAIL]: found errors/warnings while linting $f"
            fi
        fi
    done
    unset dir
}

source_file_if_available() {
    FILE="${1}"
    VARIABLE_NAME="${2}"
    if [ -f "$FILE" ]; then
        # shellcheck source=/dev/null
        . "$FILE"
    else
        echo "WARNING: Cannot source $VARIABLE_NAME (set to: $FILE) because the destination doesn't exist or the variable is set to an empty value."
        return 1
    fi
    return 0
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
    if [ -d "$destination_dir" ]; then
        echo "Updating $program_name in: $destination_dir"
        git -C "$destination_dir" pull
    else
        echo "WARNING: $destination_dir doesn't exists"
    fi
    unset destination_dir
    unset program_name
}

update_system() {
    os_name="$(uname -s)"
    if test "${os_name#*"Darwin"}" != "$os_name"; then
        echo "Updating macOS..."
        sudo softwareupdate -ia
        if command -v brew >/dev/null 2>&1; then
            update_brew
        fi
    elif test "${os_name#*"Linux"}" != "$os_name"; then
        echo "Updating linux..."
        sudo apt-get -q update
        sudo apt-get -qy upgrade
        pull_from_git_repository "$(dirname "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH")" "zsh-autosuggestions"
        pull_from_git_repository "$(dirname "$ZSH_COMPLETIONS_PATH")" "zsh-completions"
        pull_from_git_repository "$RBENV_DIRECTORY_PATH" "rbenv"
        pull_from_git_repository "$RUBY_BUILD_DIRECTORY_PATH" "ruby-build"
        pull_from_git_repository "$(dirname "$ZSH_THEME_PATH")" "powerlevel10k"
    fi
    unset os_name

    if command -v npm >/dev/null 2>&1; then
        echo "Updating npm packages"
        sudo npm update -g
    fi

    if command -v gem >/dev/null 2>&1; then
        echo "Updating gems"
        gem update
    fi
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

yamllint_dir() {
    dir=
    if [ $# -eq 0 ]; then
        dir="$(pwd)"
    else
        dir="${1}"
    fi
    find "$dir" -type f \( -iname \*.yml -o -iname \*.yaml \) -not -path "*/\\.git/*" | sort -u | while read -r f; do
        if yamllint --strict "$f"; then
            echo "[OK]: sucessfully linted $f"
        else
            echo "[FAIL]: found errors/warnings while linting $f"
        fi
    done
    unset dir
}

# Use Git’s colored diff when available
if command -v git >/dev/null 2>&1; then
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
