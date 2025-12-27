# This function creates a container image based on the
# provided configuration.

{
  nixpkgs,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  format ? "docker",
}:

let
  pkgs = import nixpkgs {
    inherit system overlays;
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
    };
  };

in
inputs.nixos-generators.nixosGenerate {
  inherit system format;

  modules = [
    { nixpkgs.pkgs = pkgs; }
    ../systems/share
    ../systems/nixos/docker
    ../images/${name}.nix
    ../users/${user}/nixos.nix
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { };
        users.${user} = ../users/${user}/home/image.nix;
      };
    }
  ];
}
