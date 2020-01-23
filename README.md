# dotfiles

[![Build Status Master Branch](https://travis-ci.org/ferrarimarco/dotfiles.svg?branch=master)](https://travis-ci.org/ferrarimarco/dotfiles)

These are the dotfiles I use on my systems.

## Installation

To install these dotfiles:

1. Clone this repository
1. Run `make` (all the dotfiles and binaries will be symlinked to their destinations so you can update them just by `git pull`ing the latest changes)

### Customization

#### Values

Write your values in the [`.extra`](.extra) file.

## Contents

### Shell customizations

To avoid repetitions, the customizations are categorized considering the type of shell they are applicable to. All the customizations are in the [`.shells`](.shells) directory:

-   The [`.bash`](.shells/.bash/) directory contains scripts for Bash.
-   The [`.sh`](.shells/.sh/) directory contains scripts for the Bourne shell.
-   The [`.zsh`](.shells/.zsh/) directory contains scripts for the Z shell.
-   The scripts in the [`.all`](.shells/.all/) directory are executed by all the shells.

### Binaries

#### setup.sh

[`setup.sh`](bin/setup.sh) sets up linux and macOS systems the way I like. Run it with no args to see what it does.

#### install-windows.ps1

[`install-windows.ps1`](bin/install-windows.ps1) sets up Windows systems the way I like.

## Development

- `make`: install dotfiles, bins and configuration files
- `make help`: shows the help text
- `make test`: run tests

## Thanks

- [Jessie Frazelle](https://github.com/jessfraz/dotfiles).
- [Kevin Suttle](https://github.com/kevinSuttle/dotfiles).
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles).
- [Nicolas Gallagher](https://github.com/necolas/dotfiles).
- [Peter Ward](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html).
