---
name: nix-developer
description:
  Develop declarative Nix and NixOS configurations. Use when the user asks to
  create, update, or debug Nix code, Nix development shells, Home Manager
  setups, NixOS hosts, or reproducible environments, or you need to develop Nix
  code.
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
  and `statix`. Run formatting with `nix fmt`. For more information, see
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
- Recommend setting up `direnv` with `use flake` in `.envrc` for automatic shell
  loading.

### 2. NixOS Host Configuration

When configuring a NixOS machine, prioritize testability and separation of
concerns by splitting configuration layers:

- **Logical Configuration (`configuration.nix`):** Declare all logical
  features—roles, logical packages, system services (e.g. SSH), local users,
  state version, and network parameters. This file should remain agnostic of
  physical hardware.
- **Physical Entrypoint (`default.nix`):** A thin entrypoint module that only
  imports the logical configuration (`configuration.nix`), physical hardware
  profile (`hardware.nix`), and disk partition definitions (`disko.nix`).
- **Submodule Encapsulation:** Keep the high-level entrypoint clean by importing
  hardware/filesystem modules (e.g., `inputs.disko.nixosModules.disko`) directly
  inside the configuration submodules that require them (e.g., `disko.nix`),
  rather than at the top level.
- **Expose via Flakes:** Expose the complete target system under
  `nixosConfigurations` in `flake.nix` importing the physical `default.nix`
  entrypoint.

### 3. Home Manager (User Environment)

When configuring user-specific dotfiles or packages:

- Utilize `home-manager` as a NixOS module or as a standalone flake output.
- Structure configurations by grouping related programs (e.g., `git`, `shell`,
  `editor`).

### 4. Integration Testing & Verification

To verify NixOS host configurations in a robust, reproducible way, implement
sandboxed VM integration tests:

- **Service-Aware VM Testing:** Use the NixOS test framework (`nixosTest` /
  `pkgs.testers.nixosTest`) to run VMs in QEMU. Prioritize declarative,
  auto-deriving test generators (`make-test.nix`) that analyze the host's
  evaluated system configuration to dynamically provision QEMU serial devices
  and dynamically concatenate Python test assertions.
- **Zero-Maintenance Flake Discovery:** Avoid manual check declarations.
  Configure `flake.nix` checks to auto-scan the `hosts/` directory and
  automatically register any host that has a `test.nix` file, ensuring CI
  instantly tests any new host configuration.
- **Pure-Evaluation Mocking:** Utilize conditional paths (`builtins.pathExists`)
  and VM-overrides (`lib.mkVMOverride`) in the test suite to dynamically mock
  out private/non-tracked keys and configuration files, ensuring isolated tests
  evaluate successfully.
- **Read the Reference Guide:** For a complete walkthrough, implementation
  example, and advanced debugging/mocking tips, see
  [references/nix-testing.md](references/nix-testing.md).

## Best Practices

- **Pinning:** Keep inputs pinned and explicitly manage `flake.lock`.
- **Modularity:** Split large configurations into separate modules using the
  `imports = [ ... ];` pattern.
- **Reviewing Changes:** When modifying configurations, review the resulting
  diffs and use `nix flake check` or `nix build` to validate syntax and
  evaluation before applying.
- **Developer Workflow & Debugging:**
  - Use `nix eval --raw .#checks.<system>.<test-name>.testScript` to dry-run
    evaluate and inspect compiled Python test scripts without booting a VM.
  - When writing VM test assertions for asynchronous services (like QEMU guest
    agent), use `machine.wait_for_file` to block until udev creates the device
    node before asserting on the service unit.
  - See [references/nix-testing.md](references/nix-testing.md) for advanced
    testing best practices.

### Flake development

- Explicitly pin the flake to a release branch (e.g.,
  `url = "github:NixOS/nixpkgs/nixos-25.11"`).
- Use `inputs.nixpkgs.follows` to unify `nixpkgs` across all inputs.
- Pass inputs to modules using `specialArgs = { inherit inputs; }`.
