---
name: nix-developer
description: >-
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
  and `statix`. Run formatting with `nix fmt` from the flake's directory: its
  arguments are files to format, and it resolves the flake from the current
  directory, so `nix fmt <flake directory>` run from elsewhere fails with "is
  not part of a flake" (nix 2.34). For more information, see
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

### 4. Integration Testing and Verification

Verify NixOS host configurations with sandboxed VM integration tests:

- **Service-Aware VM Testing:** Use the NixOS test framework (`nixosTest` /
  `pkgs.testers.nixosTest`) to run VMs in QEMU. Prioritize declarative,
  auto-deriving test generators (`make-test.nix`) that analyze the host's
  evaluated system configuration to dynamically provision QEMU serial devices
  and dynamically concatenate Python test assertions.
- **Automatic Flake Discovery:** Avoid manual check declarations. Configure
  `flake.nix` checks to auto-scan the `hosts/` directory and automatically
  register any host that has a `test.nix` file, ensuring CI instantly tests any
  new host configuration.
- **Pure-Evaluation Mocking:** Utilize conditional paths (`builtins.pathExists`)
  and VM-overrides (`lib.mkVMOverride`) in the test suite to dynamically mock
  out private/non-tracked keys and configuration files, ensuring isolated tests
  evaluate successfully.
- **Read the Reference Guide:** For a complete walkthrough, implementation
  example, and advanced debugging/mocking tips, see
  [references/nix-testing.md](references/nix-testing.md).

## Best Practices

- **Pinning:** Keep inputs pinned and explicitly manage `flake.lock`.
- **Module reconciliation defaults:** before keeping part of a service's
  configuration imperative (managed through its API or GUI), read the module's
  activation-time reconciliation behavior in the nixpkgs source at the version
  in use. Many modules delete or replace undeclared objects on every activation
  by default (e.g. `services.syncthing` `overrideDevices` and `overrideFolders`
  default to `true` and delete undeclared devices and folders as stale even when
  the configuration declares none), and declared objects are re-applied
  wholesale, stripping imperatively added fields. Replacement can also act at
  the settings-section level: declaring a single key can reset the section's
  undeclared keys on every activation. Disable such flags explicitly, leave
  sections holding imperative fields undeclared, and verify the imperative state
  survives the first activation. The deployed generation's setup unit is the
  authoritative version-in-use evidence: locate it in the module source, read
  the script it runs, and note the API verbs and which calls can fail silently.
  When the behavior is a defect, check nixpkgs master for an upstream fix before
  designing a workaround, and record which release delivers it. The same reading
  covers access control: a module that always writes an access-control file (an
  ACL and a password file per listener, as `services.mosquitto` does) denies
  what the daemon's own defaults allow, so an open service needs explicit
  permissive settings, and its test needs a client of each identity the
  consumers use.
- **Modularity:** Split large configurations into separate modules using the
  `imports = [ ... ];` pattern.
- **Reviewing Changes:** When modifying configurations, review the resulting
  diffs and use `nix flake check` or `nix build` to validate syntax and
  evaluation before applying.
- **Developer Workflow and Debugging:**
  - To inspect the compiled Python test script without building or booting
    anything, evaluate the test framework's internal option that holds it:
    `nix eval --raw .#checks.<system>.<test-name>.config.testScriptString`. The
    test derivation exposes no `testScript` attribute, and `config.testScript`
    is a functor when the generator declares `testScript = { nodes, ... }: ...`,
    so `nix eval --raw` fails on both. Building the `driver` output also runs
    the script through mypy and pyflakes and writes it to
    `<driver>/test-script`, but it pulls in the nodes' VM closures.
  - A check proves only what its steps exercise, and its comment claims no more:
    a persistence claim needs a restart between the write and the read (a
    Mosquitto broker serves retained messages from its in-memory database, which
    reaches the store a restart reloads at shutdown, every `autosave_interval`
    of 30 minutes by default, and on SIGUSR1, so within a test only the shutdown
    write lands), and a claim about an access rule needs a client of each
    identity the consumers use.
  - When writing VM test assertions for asynchronous services (like QEMU guest
    agent), use `machine.wait_for_file` to block until udev creates the device
    node before asserting on the service unit.
  - The test driver's `machine.succeed` runs commands under `pipefail`, so an
    early-exiting pipe consumer (`grep -q`) on a large producer fails the
    pipeline; use a consumer that reads the full stream, such as
    `grep <pattern> > /dev/null`.
  - `machine.wait_for_unit` proves the unit is active, not that the service
    accepts requests (under boot load, probes right after activation can be
    refused or return incomplete responses): assert on behavior with
    `machine.wait_until_succeeds(..., timeout=N)` instead of a one-shot
    `machine.succeed`.
  - See [references/nix-testing.md](references/nix-testing.md) for advanced
    testing best practices.

### Flake development

- Explicitly pin the flake to a release branch (e.g.,
  `url = "github:NixOS/nixpkgs/nixos-25.11"`).
- Use `inputs.nixpkgs.follows` to unify `nixpkgs` across all inputs.
- Pass inputs to modules using `specialArgs = { inherit inputs; }`.
- In a Git repository, flake evaluation only sees Git-tracked files: `git add`
  newly created files before building or evaluating, or they are invisible and
  evaluation fails with a "not tracked by Git" error.
- Build flake checks with `--no-link` when the repository's `result` symlink
  carries meaning (e.g. staged build artifacts another tool consumes), so the
  check build does not clobber it.

### References

- [Nix command reference](references/nix-commands.md)
- [treefmt example](references/nix-treefmt.md)
- [NixOS Integration Testing Reference Guide](references/nix-testing.md)
