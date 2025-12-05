{
  description = "NixOS System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nix-ai-tools,
      ...
    }@inputs:
    let
      # Overlays is the list of overlays we want to apply from flake inputs.
      overlays = import ./overlays/default.nix;

      mkSystem = import ./packages/mksystem.nix {
        inherit
          overlays
          nixpkgs
          nixpkgs-unstable
          nix-ai-tools
          inputs
          ;
      };

    in
    {
      darwinConfigurations.bm-macbook-pro-m1-prv = mkSystem "bm-macbook-pro-m1-prv" {
        system = "aarch64-darwin";
        user = "iamralch";
      };

      darwinConfigurations.bm-macbook-pro-m1-wrk = mkSystem "bm-macbook-pro-m1-wrk" {
        system = "aarch64-darwin";
        user = "iamralch";
      };
    };
}
