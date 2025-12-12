# This function creates a NixOS system based on our VM setup for a
# particular architecture.

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

  # System Modules
  system-name = if isDarwin then "macos" else "nixos";
  # System builder function
  system-manager = if isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  # Home Manager
  host-name = name;
  home-manager =
    if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
    };
  };

in
system-manager {
  inherit system;

  specialArgs = {
    inherit
      inputs
      pkgs
      ;
  };

  modules = [
    # Apply our overlays. Overlays are keyed by system type so we have
    # to go through and apply our system type. We do this first so
    # the overlays are available globally.
    { nixpkgs.overlays = overlays; }

    # system configuration
    ../systems/share
    ../systems/${system-name}
    # host configuration
    ../hosts/${host-name}.nix
    # user configuration
    ../users/${user}/${system-name}.nix
    # home-manager configuration
    home-manager.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users.${user} = import ../users/${user}/home.nix {
          inherit
            inputs
            pkgs
            ;
        };
      };
    }
  ];
}
