---
name: nix-developer
description:
  Develop declarative Nix and NixOS configurations. Use when the user asks to
  create, update, or debug Nix development shells, Home Manager setups, NixOS
  hosts, or reproducible environments.
license: MIT
---

# Nix Developer

This skill provides expertise in developing modern, reproducible Nix and NixOS
configurations.

## Core Principles

- **Prefer Flakes:** Always default to using Nix Flakes (`flake.nix`) for new
  configurations and shells, as they are the modern standard for
  reproducibility.
- **Declarative Over Imperative:** Avoid `nix-env` or imperative state
  manipulation. Everything should be declared in code.
- **Formatting and linting:** Configure `treefmt` to run `nixfmt`, `deadnix`,
  and `statix`. For more information, see
  [references/nix-treefmt.md](references/nix-treefmt.md).

## Workflows

### 1. Set up a project environment

When tasked with setting up a project environment:

- Create a `flake.nix` with an `outputs` function providing a
  `devShells.<system>.default`.
- Use `mkShell` from `nixpkgs` to define `buildInputs` (runtime dependencies)
  and `nativeBuildInputs` (build tools).
- Include standard development tools (e.g., linters, LSPs) relevant to the
  project's primary languages.

### 2. NixOS Host Configuration

When configuring a NixOS machine:

- Organize configurations logically, separating hardware specifics
  (`hardware-configuration.nix`) from logical services and packages.
- Ensure the configuration is exposed via `nixosConfigurations` in a root
  `flake.nix`.

### 3. Home Manager (User Environment)

When configuring user-specific dotfiles or packages:

- Utilize `home-manager` as a NixOS module or as a standalone flake output.
- Structure configurations by grouping related programs (e.g., git, shell,
  editor).

## Best Practices

- **Pinning:** Keep inputs pinned and explicitly manage `flake.lock`.
- **Modularity:** Split large configurations into separate modules using the
  `imports = [ ... ];` pattern.
- **Reviewing Changes:** When modifying configurations, review the resulting
  diffs and use `nix flake check` or `nix build` to validate syntax and
  evaluation before applying.

### Flake development

- Explicitly pin the flake to a release branch:
  `url = "github:nixos/nixpkgs/nixos-25.11"`.
- Use `inputs.nixpkgs.follows` to unify `nixpkgs` across all inputs.
- Pass inputs to modules using `specialArgs = { inherit inputs; }`.
