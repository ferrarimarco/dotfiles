# dotfiles

[![Build Status Master Branch](https://travis-ci.com/ferrarimarco/dotfiles.svg?branch=master)](https://travis-ci.com/ferrarimarco/dotfiles)

These are the dotfiles I use on my systems.

## Installation

To install these dotfiles:

1. Clone this repository with Git.
1. Setup the dotfiles:
    - If you're on a Unix-based system (Linux, macOS):
        1. `bin/setup-dotfiles.sh` on Linux-based system, Windows Subsystem for
            Linux, or macOS.
    - If you're on Windows:
        1. `bin/install-windows.ps1` from a Powershell shell on Windows.
        1. Start the Windows Subsystem for Linux.
1. Run `make` (all the dotfiles and binaries will be symlinked to their
    destinations so you can update them just by `git pull`ing the latest changes)

Run `make help` for a list of the available run targets, including the ones
useful for development.

## Contents

### Software configuration

- Visual Studio Code
- Windows Subsystem for Linux
- XFCE
- cURL
- Git
- Tmux
- Wget

### Shell customizations

To avoid repetitions, the customizations are categorized considering the type of
shell they are applicable to. All the customizations are in the
[`.shells`](.shells) directory:

- The [`.bash`](.shells/.bash/) directory contains scripts for Bash.
- The [`.sh`](.shells/.sh/) directory contains scripts for the Bourne shell.
- The [`.zsh`](.shells/.zsh/) directory contains scripts for the Z shell.
- The scripts in the [`.all`](.shells/.all/) directory are executed by all the
    shells.

### Git hooks

- `pre-commit` that runs linting and checks before committing.
- `commit-msg` that adds a `Change-Id` to the commit message, if necessary.

## Thanks

- [Jessie Frazelle](https://github.com/jessfraz/dotfiles)
- [Kevin Suttle](https://github.com/kevinSuttle/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Nicolas Gallagher](https://github.com/necolas/dotfiles)
- [Peter Ward](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html)
