# treefmt example

This example shows how to configure `treefmt` to run `nixfmt`, `deadnix`, and
`statix`.

Define `treefmt` configuration in a `treefmt.nix` file:

```nix
  { pkgs }:
  {
    # Used to find the project root
    projectRootFile = "flake.nix";

    programs = {
      deadnix.enable = true;
      statix.enable = true;

      nixfmt = {
        enable = true;
        package = pkgs.nixfmt;
      };
    };
  }
```

Then, load this configuration in a flake (`flake.nix`):

```nix
{
description = "Example flake";

inputs = {
  # Reference in case we want to switch to unstable
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  treefmt-nix.url = "github:numtide/treefmt-nix";
  treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
};

outputs =
  {
    self,
    nixpkgs,
    treefmt-nix,
    ...
  }@inputs:
  let
    system = "x86_64-linux";

    # Use legacyPackages instead of packages to avoid evaluating unneeded
    # packages.
    # Ref: https://github.com/NixOS/nixpkgs/blob/1073dad219cb244572b74da2b20c7fe39cb3fa9e/flake.nix#L206
    pkgs = nixpkgs.legacyPackages.${system};

    treefmtEval = treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix { inherit pkgs; });
  in
  {
    formatter.${system} = treefmtEval.config.build.wrapper;

    checks.${system} = {
      treefmt-nix = treefmtEval.config.build.check self;
    };
  };
}
```
