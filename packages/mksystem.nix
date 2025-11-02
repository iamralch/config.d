# This function creates a NixOS system based on our VM setup for a
# particular architecture.

{
  nixpkgs,
  nixpkgs-unstable,
  nix-ai-tools,
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

  upkgs = import nixpkgs-unstable {
    inherit system;
    inherit (pkgs) config;
  };

  extras = {
    ai = nix-ai-tools.packages.${system};
  };
in
system-manager {
  inherit system;

  specialArgs = {
    inherit
      inputs
      extras
      upkgs
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
        extraSpecialArgs = { inherit inputs extras upkgs; };
        users.${user} = import ../users/${user}/home.nix {
          inherit
            inputs
            extras
            upkgs
            pkgs
            ;
        };
      };
    }
  ];
}
