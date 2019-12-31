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

- The [`.bash`](.shells/.bash/) directory contains scripts for Bash.
- The [`.sh`](.shells/.sh/) directory contains scripts for the Bourne shell.
- The scripts in the [`.all`](.shells/.all/) directory are executed by all the shells.

### Binaries

#### install-linux.sh

[This shell script](bin/install-linux.sh) sets up linux systems the way I like. After installing the dotfiles, run it with no args to see what it does:

```shell
install-linux.sh
```

#### install-macos.sh

[This shell script](bin/install-macos.sh) sets up macOS systems the way I like. After installing the dotfiles, run it with no args to see what it does:

```shell
install-macos.sh
```

#### Homebrew

To install Homebrew run:

```shell
install-macos.sh homebrew
```

Then you can install the predefined formulae by running:

```shell
install-macos.sh homebrew-formulae
```

##### Path

If you want to use the executables installed by Homebrew instead of the ones bundled with macOS, uncomment the relevant lines in [`.path`](.path).

## Development

- `make`: install dotfiles, bins and configuration files
- `make help`: shows the help text
- `make test`: run tests

## Thanks

- [Jessie Frazelle](https://github.com/jessfraz/dotfiles).
- [Kevin Suttle](https://github.com/kevinSuttle/dotfiles).
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles).
- [Nicolas Gallagher](https://github.com/necolas/dotfiles).
- [Peter Ward](https://bitbucket.org/flowblok/shell-startup).
