# This function creates a dev shell with shared packages.

{
  nixpkgs,
  overlays,
}:

system:

let
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  sharedConfig = import ../systems/share/packages.nix { inherit pkgs; };

in
pkgs.mkShell {
  packages = sharedConfig.environment.systemPackages;
}
