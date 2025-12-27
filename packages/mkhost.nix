# This function creates a NixOS/Darwin host based on the
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
}:

let
  isDarwin = nixpkgs.lib.hasSuffix "darwin" system;
  system-name = if isDarwin then "macos" else "nixos";

  system-manager = if isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;

  home-manager =
    if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

  pkgs = import nixpkgs {
    inherit system overlays;
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
    };
  };

  # Read-only pkgs module path
  readOnlyPkgs = "${nixpkgs}/nixos/modules/misc/nixpkgs/read-only.nix";

in
system-manager {
  inherit system;

  modules = [
    { nixpkgs.pkgs = pkgs; }
    ../systems/share
    ../systems/${system-name}
    ../hosts/${name}.nix
    ../users/${user}/${system-name}.nix
    home-manager.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { };
        users.${user} = ../users/${user}/home/${system-name}.nix;
      };
    }
  ]
  ++ (if isDarwin then [ inputs.determinate.darwinModules.default ] else [ readOnlyPkgs ]);
}
