# dotfiles

[![CI](https://github.com/ferrarimarco/dotfiles/actions/workflows/main.yml/badge.svg)](https://github.com/ferrarimarco/dotfiles/actions/workflows/main.yml)

These are the dotfiles I use on my systems and development environments.

## Installation

To install these dotfiles:

1. Clone this repository with Git.
1. Setup the dotfiles.

   If you're on a Unix-based system (Linux, macOS, Windows Subsystem for Linux),
   run:

   ```sh
   SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" ./setup.sh
   ```

   If you're on Windows, open a PowerShell session and run:

   ```powershell
   setup-windows.ps1
   ```

All the dotfiles and binaries will be symlinked to their destinations so you can
update them just by pulling the latest changes.

## Contents

This section describes the customizations and configurations included in these
dotfiles.

### Agent skills

#### Design

- `design-spec`: Design specifications for new features.
- `validate-spec`: Validate a specification (spec) to spot ambiguities,
  inconsistencies, unclear or missing instructions, data, information, or
  requirements.
- `maintain-living-specs`: Automate the synchronization of living design
  specifications (Markdown) with code changes in the repository.

#### Development

- `ansible-developer`: Develop Ansible roles and playbooks.
- `git-commit`: Execute Git commit with conventional commit message.
- `nix-developer`: Develop declarative Nix and NixOS configurations.
- `terraform-developer`: Develop declarative Terraform configurations.

### Software configuration

The dotfiiles include configuration files for the following software:

- Antigravity CLI
- Claude Code
- cURL
- Git:
  - [`.gitconfig`](.gitconfig): Global Git config containing core preferences,
    and productivity aliases.
  - [`.gitconfig-workspaces`](.gitconfig-workspaces): GitHub Workspace-specific
    config.
  - [`gitignore`](gitignore): Global Git ignore list to exclude common
    temporary, system, and editor files.
- iTerm2
- Nano
- Nix
- SSH client
- Terraform
- Tmux
- Visual Studio Code
- Wget
- Windows Subsystem for Linux

### Shell customizations

The dotfiles include customization and configuration files for different shells.

To avoid repetitions, the customizations are categorized considering the type of
shell they are applicable to. All the customizations are in the
[`.shells`](.shells) directory:

- The [`.bash`](.shells/.bash/) directory contains scripts for Bash.
- The [`.sh`](.shells/.sh/) directory contains scripts for the Bourne shell.
- The [`.zsh`](.shells/.zsh/) directory contains scripts for the Z shell.
- The scripts in the [`.all`](.shells/.all/) directory are executed by all the
  shells.

### Git hooks

The dotfiles include a the following Git hooks. For each Git hook type,
`.git-hooks/git-hook-runner.sh` will run the hooks listed in the
`.git-hooks/<Git hook name>.d` directory in alphabetic order.

- `commit-msg` hooks:
  - `100-gerrit-commit-msg`: adds a `Change-Id` trailer to the commit message.
    Useful when working with Gerrit. This hook is disabled by default. Enable it
    by running:

    ```sh
    git config core.hooksPath .git/hooks
    ```
