#!/bin/bash
set -e
set -o pipefail

# install.sh
#	This script installs my basic setup for a linux workstation

# Choose a user account to use for this installation
get_user() {
	if [ -z "${TARGET_USER-}" ]; then
		mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
		# if there is only one option just use that user
		if [ "${#options[@]}" -eq "1" ]; then
			readonly TARGET_USER="${options[0]}"
			echo "Using user account: ${TARGET_USER}"
			return
		fi

		# iterate through the user options and print them
		PS3='Which user account should be used? '

		select opt in "${options[@]}"; do
			readonly TARGET_USER=$opt
			break
		done
	fi
}

check_is_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root."
		exit
	fi
}

setup_docker(){
  if command -v docker >/dev/null 2>&1 ; then
    echo "Docker is already installed"
  else
    curl -sSL https://get.docker.com | sh
  fi

  if command -v docker-compose >/dev/null 2>&1 ; then
    echo "Docker Compose is already installed"
  else
    docker_compose_release="$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" |  grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
    curl -L https://github.com/docker/compose/releases/download/"$docker_compose_release"/docker-compose-"$(uname -s)"-"$(uname -m)" -o /usr/local/bin/docker-compose
    chmod a+x /usr/local/bin/docker-compose
  fi
}

setup_dotfiles() {
	# create subshell
	(
	cd "$HOME"

	if [[ ! -d "${HOME}/dotfiles" ]]; then
		# install dotfiles from repo
		git clone git@github.com:ferrarimarco/dotfiles.git "${HOME}/dotfiles"
	fi

	cd "${HOME}/dotfiles"

	# installs all the things
	make
	)

}

# setup sudo for a user
setup_sudo() {
	# add user to sudoers
	adduser "$TARGET_USER" sudo

	# add user to systemd groups
	# then you wont need sudo to view logs and shit
	gpasswd -a "$TARGET_USER" systemd-journal
	gpasswd -a "$TARGET_USER" systemd-network

	# create docker group
	getent group docker >/dev/null 2>&1 || groupadd docker
	gpasswd -a "$TARGET_USER" docker

	{ \
		echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
		echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
	} >> /etc/sudoers
}

setup_user() {
  mkdir -p "/home/$TARGET_USER/Downloads"
  mkdir -p "/home/$TARGET_USER/Pictures/Screenshots"
}

usage() {
	echo -e "install.sh\\n\\tThis script installs my basic setup for a linux workstation\\n"
	echo "Usage:"
	echo "  base                                - setup sudo, user and docker"
	echo "  dotfiles                            - get dotfiles"
}

main() {
	local cmd=$1

	if [[ -z "$cmd" ]]; then
		usage
		exit 1
	fi

	if [[ $cmd == "base" ]]; then
		check_is_sudo
		get_user
    setup_sudo
    setup_user
    setup_docker
	elif [[ $cmd == "dotfiles" ]]; then
		get_user
		setup_dotfiles
	else
		usage
	fi
}

main "$@"
