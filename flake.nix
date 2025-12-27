{
  description = "NixOS System Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      # Overlays is the list of overlays we want to apply from flake inputs.
      overlays = import ./overlays/default.nix;

      mkHost = import ./packages/mkhost.nix {
        inherit overlays nixpkgs inputs;
      };

      mkImage = import ./packages/mkimage.nix {
        inherit overlays nixpkgs inputs;
      };

    in
    {
      darwinConfigurations.bm-macbook-pro-m1-prv = mkHost "bm-macbook-pro-m1-prv" {
        system = "aarch64-darwin";
        user = "iamralch";
      };

      darwinConfigurations.bm-macbook-pro-m1-wrk = mkHost "bm-macbook-pro-m1-wrk" {
        system = "aarch64-darwin";
        user = "iamralch";
      };

      dockerConfigurations.oci-docker-prv = mkImage "oci-docker-prv" {
        system = "aarch64-linux";
        user = "iamralch";
      };
    };
}
