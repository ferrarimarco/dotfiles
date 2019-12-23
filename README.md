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
- The scripts in the [`.all`](.shells/.all/) directory are executed by all the shells.

### Binaries

#### install-linux.sh

[This shell script](bin/install-linux.sh) sets up linux systems the way I like. After installing the dotfiles, run it with no args to see what it does:

```bash
install-linux.sh
```

#### install-macos.sh

[This shell script](bin/install-macos.sh) sets up macOS systems the way I like. After installing the dotfiles, run it with no args to see what it does:

```bash
install-macos.sh
```

#### Homebrew

The provided [maintenance binaries](bin/install-macos.sh) patch [Homebrew](https://brew.sh) on the first installation (and after every upgrade) to allow the personalization
of the Homebrew Cellar path.

To install Homebrew run:

```bash
install-macos.sh homebrew
```

Then you can install the predefined formulae by running:

```bash
install-macos.sh homebrew-formulae
```

##### Path

If you want to use the executables installed by Homebrew instead of the ones bundled with macOS, uncomment the relevant lines in [`.path`](.path).

## Development

- `make`: install dotfiles, bins and configuration files
- `make help`: shows the help text
- `make test`: run tests

## Thanks

- [Jessie Frazelle](https://blog.jessfraz.com/) for her awesome [.dotfiles](https://github.com/jessfraz/dotfiles) and [dockerfiles](https://github.com/jessfraz/dockerfiles) repos.
- [Kevin Suttle](https://github.com/kevinSuttle) for his [dotfiles](https://github.com/kevinSuttle/dotfiles)
- [Mathias Bynens](https://mathiasbynens.be/) for his [dotfiles](https://github.com/mathiasbynens/dotfiles)
- [Nicolas Gallagher](https://github.com/necolas) for his [dotfiles](https://github.com/necolas/dotfiles)
