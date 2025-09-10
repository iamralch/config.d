{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
}:

let
  # System Modules
  system-generator =  inputs.nixos-generators.nixosGenerate;
  system-name = "nixos";
  # Home Manager
  home-manager = inputs.home-manager.nixosModules;
  host-name = name;
in system-generator {
  inherit system;

  # Format
  format = "docker";

  # name/tag metadata
  specialArgs = { inherit host-name user; };

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
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user} = import ../users/${user}/home.nix {
          inherit inputs;
        };
      };
    }
  ];
}
