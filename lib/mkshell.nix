# This function creates a dev shell with shared packages.

{
  nixpkgs,
  nixpkgs-unstable,
  overlays,
}:

system:

let
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  pkgs-unstable = import nixpkgs-unstable {
    inherit system overlays;
    config.allowUnfree = true;
  };

  sharedConfig = import ../systems/share/packages.nix {
    inherit pkgs pkgs-unstable;
  };

in
pkgs.mkShell {
  packages = sharedConfig.environment.systemPackages;
}
