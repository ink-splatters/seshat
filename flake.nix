{
  description = "Description for the project";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-analyzer-src.follows = "";
      };
    };
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      withSystem,
      flake-parts-lib,
      ...
    }: let
      inherit (flake-parts-lib) importApply;
      systems = import inputs.systems;
      flakeModules.default = importApply ./flake-module.nix {inherit withSystem;};
    in {
      debug = true;

      imports = [
        flakeModules.default
      ];
      inherit systems;

      perSystem = {
        pkgs,
        config,
        ...
      }: {
        formatter = pkgs.alejandra;
        packages.default = config.packages.seshat;
      };
      flake = {
        inherit flakeModules;
      };
    });
}
