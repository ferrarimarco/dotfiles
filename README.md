# dotfiles

[![CI](https://github.com/ferrarimarco/dotfiles/actions/workflows/main.yml/badge.svg)](https://github.com/ferrarimarco/dotfiles/actions/workflows/main.yml)

These are the dotfiles I use on my systems and development environments.

## Installation

To install these dotfiles:

1. Clone this repository with Git.
1. Setup the dotfiles:
    - If you're on a Unix-based system (Linux, macOS, Windows Subsystem for
        Linux):

        1. `SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" ./setup.sh`

    - If you're on Windows:

        1. `setup-windows.ps1` from a Powershell shell on Windows.

All the dotfiles and binaries will be symlinked to their destinations so you can
update them just by pulling the latest changes.

## Contents

This section describes the customizations and configurations included in these
dotfiles.

### Software configuration

The dotfiiles include configuration files for the following softwares:

- cURL
- Git
- Nano
- SSH client
- Terraform
- Tmux
- Visual Studio Code
- Wget
- Windows Subsystem for Linux

### Shell customizations

The dotfiles include customization and configuration files for different
shells.

To avoid repetitions, the customizations are categorized considering the type of
shell they are applicable to. All the customizations are in the
[`.shells`](.shells) directory:

- The [`.bash`](.shells/.bash/) directory contains scripts for Bash.
- The [`.sh`](.shells/.sh/) directory contains scripts for the Bourne shell.
- The [`.zsh`](.shells/.zsh/) directory contains scripts for the Z shell.
- The scripts in the [`.all`](.shells/.all/) directory are executed by all the
    shells.

### Git hooks

The dotfiles include the following Git hooks:

- `commit-msg` that adds a `Change-Id` to the commit message, if necessary.
  Useful when working with Gerrit.

## Thanks

I used these dotfiles as inspiration and guidance:

- [Jessie Frazelle](https://github.com/jessfraz/dotfiles)
- [Kevin Suttle](https://github.com/kevinSuttle/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Nicolas Gallagher](https://github.com/necolas/dotfiles)
- [Peter Ward](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html)
