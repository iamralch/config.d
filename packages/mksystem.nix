# This function creates a NixOS system based on our VM setup for a
# particular architecture.

{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
}:

let
  isDarwin = nixpkgs.lib.hasSuffix "darwin" system;

  # System Modules
  system-manager = if isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  system-name = if isDarwin then "macos" else "nixos";
  # Home Manager
  home-manager = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  host-name = name;
in system-manager {
  inherit system;

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
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/${user}/home.nix {
        inputs = inputs;
      };
    }
  ];
}
