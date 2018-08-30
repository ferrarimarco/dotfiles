#!/bin/bash
set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# install-linux.sh
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

# install/update golang from source
install_golang() {
	export GO_VERSION
	GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
	export GO_SRC=/usr/local/go

	# if we are passing the version
	if [[ ! -z "$1" ]]; then
		GO_VERSION=$1
	fi

	# purge old src
	if [[ -d "$GO_SRC" ]]; then
		sudo rm -rf "$GO_SRC"
		sudo rm -rf "$GOPATH"
	fi

	GO_VERSION=${GO_VERSION#go}

	# subshell
	(
	kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
	curl -sSL "https://storage.googleapis.com/golang/go${GO_VERSION}.${kernel}-amd64.tar.gz" | sudo tar -v -C /usr/local -xz
	local user="$USER"
	# rebuild stdlib for faster builds
	sudo chown -R "${user}" /usr/local/go/pkg
	CGO_ENABLED=0 go install -a -installsuffix cgo std
	)

	# get commandline tools
	(
	set -x
	set +e

	go get github.com/genuinetools/certok
	go get github.com/genuinetools/reg
  )
	# symlink weather binary for motd
	sudo ln -snf "${GOPATH}/bin/weather" /usr/local/bin/weather
}

# install custom scripts/binaries
install_scripts() {
	# install speedtest
	curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
	chmod +x /usr/local/bin/speedtest
}

# sets up apt sources
setup_debian_sources() {
  add-apt-repository main
  add-apt-repository universe
  add-apt-repository multiverse
  add-apt-repository restricted

	apt-get update || true
	apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		dirmngr \
		gnupg2 \
		lsb-release \
		--no-install-recommends

	# Add the Google Chrome distribution URI as a package source if needed
	CHROME_APT_SOURCE_PATH="/etc/apt/sources.list.d/google-chrome.list"
	if [ -e "$CHROME_APT_SOURCE_PATH" ]
	then
	    echo "Google Chrome APT source is already installed. Contents: $(cat "$CHROME_APT_SOURCE_PATH")"
	else
		cat <<-EOF > "$CHROME_APT_SOURCE_PATH"
		deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main
		EOF
	fi

	# Import the Google Chrome public key
	curl https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
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

	# enable dbus for the user session
	systemctl --user enable dbus.socket

	sudo systemctl enable systemd-networkd systemd-resolved
	sudo systemctl start systemd-networkd systemd-resolved

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

base_debian() {
	apt-get update || true
	apt-get -y upgrade

	apt-get install -y \
		adduser \
		alsa-utils \
		apparmor \
		automake \
		bash-completion \
		bc \
    bmon \
		bridge-utils \
		bzip2 \
		coreutils \
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
		google-chrome-stable \
		grep \
		gzip \
		hostname \
    imagemagick \
		indent \
		iptables \
    jmeter \
		jq \
		less \
		libapparmor-dev \
		libc6-dev \
		libimobiledevice6 \
		libltdl-dev \
		libpam-systemd \
		libseccomp-dev \
		locales \
		lsof \
		make \
    maven \
		mount \
    nano \
    nethogs \
		net-tools \
		pinentry-curses \
		rxvt-unicode-256color \
		scdaemon \
		ssh \
		strace \
		sudo \
		systemd \
		tar \
		tree \
		tzdata \
    ubuntu-desktop \
		unzip \
		usbmuxd \
		xclip \
		xcompmgr \
		xz-utils \
		zip \
		--no-install-recommends

	apt-get autoremove
	apt-get autoclean
	apt-get clean
}

usage() {
	echo -e "install-linux.sh\\n\\tThis script installs my basic setup for a linux workstation\\n"
	echo "Usage:"
	echo "  base                                - setup sudo, user and docker"
  echo "  debian-base                         - install base packages on a Debian system"
  echo "  dotfiles                            - get dotfiles"
  echo "  golang                              - install golang and packages"
  echo "  scripts                             - install scripts"
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
  elif [[ $cmd == "debian-base" ]]; then
    check_is_sudo
		get_user
		setup_debian_sources
		base_debian
  elif [[ $cmd == "dotfiles" ]]; then
		get_user
		setup_dotfiles
  elif [[ $cmd == "golang" ]]; then
		install_golang "$2"
  elif [[ $cmd == "scripts" ]]; then
    check_is_sudo
    install_scripts
	else
		usage
	fi
}

main "$@"
