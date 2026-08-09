# NixOS Integration Testing Reference Guide

This guide explains how to design a modular, service-aware, auto-deriving
integration testing framework in NixOS using `nixosTest`.

## 1. The Auto-Deriving Test Generator Pattern

Instead of writing hardcoded test scripts and QEMU hardware options for every
host, you can design a generic test generator (`make-test.nix`) that inspects
the VM's evaluated configuration at compile-time and **dynamically derives**
both the hardware and assertions.

### Generic Generator Example (`make-test.nix`)

This central file evaluates the host configuration and injects settings
dynamically based on enabled options:

```nix
{
  pkgs,
  hostConfiguration,
  extraConfig ? { },
  extraTestScript ? "",
}:

let
  # Extract the hostname by shallow-evaluating the host configuration function
  hostName = (import hostConfiguration { }).networking.hostName;
in
pkgs.testers.nixosTest {
  name = "${hostName}-test";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [
        hostConfiguration
        extraConfig
      ];

      # 1. Dynamic Hardware Setup:
      # If the guest agent is enabled, automatically provision virtio hardware in QEMU.
      virtualisation.qemu.options = lib.mkIf config.services.qemuGuest.enable [
        "-device virtio-serial"
        "-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"
        "-chardev null,id=qga0"  # We use 'null' in sandboxed builders (e.g. CI)
      ];
    };

  # 2. Dynamic Assertion Generation:
  # The testScript function receives evaluated nodes, allowing us to inspect
  # config values during compile-time string compilation.
  testScript =
    { nodes, ... }:
    let
      config = nodes.machine.config;

      # Dynamic check: Assert SSH port 22 if SSH is enabled
      sshCheck = if config.services.openssh.enable then ''
        machine.wait_for_open_port(22)
      '' else "";

      # Dynamic check: Assert QEMU Guest Agent if service is enabled
      qemuAgentCheck = if config.services.qemuGuest.enable then ''
        machine.wait_for_file("/dev/virtio-ports/org.qemu.guest_agent.0")
        machine.wait_for_unit("qemu-guest-agent.service")
      '' else "";
    in
    ''
      # Base boot check (common to all hosts)
      machine.wait_for_unit("multi-user.target")

      # Dynamically appended service checks
      ${sshCheck}
      ${qemuAgentCheck}

      # Custom host assertions
      ${extraTestScript}
    '';
}
```

### Host Test Wrapper (`test.nix`)

With the generator, host-specific test entrypoints become trivial wrappers:

```nix
{ pkgs, ... }:

import ../../tests/make-test.nix {
  inherit pkgs;
  hostConfiguration = ./configuration.nix;
}
```

## 2. Flake Autodiscovery of Tests

To maintain a zero-maintenance test suite, avoid manually listing host tests
inside `checks` in `flake.nix`. Instead, use Nix built-ins to auto-discover
them:

```nix
  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Discover all directories in ./hosts containing a test.nix file
      hostsDir = ./hosts;
      hostNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory") (builtins.readDir hostsDir)
      );
      hostTests = lib.listToAttrs (
        map (host: {
          name = "${host}-test";
          value = import (hostsDir + "/${host}/test.nix") { inherit pkgs; };
        }) (builtins.filter (host: builtins.pathExists (hostsDir + "/${host}/test.nix")) hostNames)
      );
    in
    {
      checks.${system} = {
        # Standard static checks (e.g. formatting)
      } // hostTests; # Automatically merges all discovered tests dynamically
    };
```

## 3. Developer Workflows & Debugging

### Dry-Run Test Script Inspection

Because Python test scripts are dynamically compiled via Nix string
interpolation, you cannot see the raw Python code inside `test.nix`.

To dry-run evaluate and print the **fully compiled Python script** exactly as
QEMU will execute it, run:

```shell
nix eval --raw .#checks.<system>.<hostname>-test.testScript
```

This compiles the string interpolations and outputs the Python source instantly
without booting a VM.

### Asynchronous Udev Boot Races

Daemons like `qemu-guest-agent` are triggered asynchronously by `udev` when the
virtual serial port device is detected. Checking them immediately using
`systemctl is-active` can race with udev processing and fail.

- **Best Practice:** Always wait for the physical hardware device node to exist
  before waiting for the service:

  ```python
  # 1. Wait for virtual hardware node to be populated by udev
  machine.wait_for_file("/dev/virtio-ports/org.qemu.guest_agent.0")

  # 2. Wait for systemd service trigger
  machine.wait_for_unit("qemu-guest-agent.service")
  ```

### Interactive VM Debugging

You can boot a test VM and interact with it manually:

1.  Start the interactive test driver (launches a Python shell):
    ```shell
    nix run .#checks.x86_64-linux.<hostname>-test.driverInteractive
    ```
2.  Inside the Python shell, start the VM:
    ```python
    start_all()
    ```
3.  Interact directly with the guest OS shell:
    ```python
    machine.shell_interact()
    ```

## 4. Pure-Evaluation Mocking Pattern (Nix-Safe Mocking)

When NixOS configurations import logical modules that depend on external,
non-Git-tracked resources (such as secrets, configuration files, or private SSH
bootstrap keys), the integration test framework (`nixosTest`) will fail to
evaluate in isolation due to missing paths.

To prevent configuration errors and avoid hardcoding mock values in production
host files, follow this **Pure-Evaluation Mocking Pattern**:

### 1. Declare Optional or Default Checks in Configuration

In the host's configuration or physical entrypoint, use `builtins.pathExists` or
`lib.mkDefault` to load physical keys conditionally:

```nix
# hosts/hl02/default.nix
let
  keyPath = ../../ssh-keys/bootstrap_id_ed25519.pub;
  bootstrapKey = if builtins.pathExists keyPath then
    builtins.readFile keyPath
  else
    "ssh-ed25519 AAAA...mock_key_for_testing..."; # Pure eval fallback
in
{
  users.users.root.openssh.authorizedKeys.keys = [ bootstrapKey ];
}
```

### 2. Inject Mock Inputs via `extraConfig` in the Test Generator

Inside the centralized integration test generator (`make-test.nix`), leverage
the `extraConfig` attribute to dynamically override configurations and stub
external dependencies during test evaluation:

```nix
# tests/make-test.nix
pkgs.testers.nixosTest {
  nodes.machine = { config, lib, ... }: {
    imports = [
      hostConfiguration
    ];

    # Override hardware profiles and keys to run in pure QEMU sandboxes
    services.openssh.enable = lib.mkVMOverride true;

    # Mock network parameters if needed
    networking.interfaces.eth0.useDHCP = lib.mkVMOverride true;
  };
}
```

Using `lib.mkVMOverride` ensures that even if a host defines rigid physical
properties, the test VM successfully forces QEMU-compatible values.
