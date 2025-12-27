{ lib, ... }:

let
  mkCopy = import ../../../modules/mkcopy.nix { inherit lib; };
in
{
  imports = [ ./home.nix ];

  home.username = "iamralch";
  home.homeDirectory = "/home/iamralch";

  home.activation = {
    zshrc = mkCopy "users/iamralch/.zshrc" "$HOME/.zshrc";
    config = mkCopy "users/iamralch/.config" "$HOME/.config";
  };

  # Disable systemd user session (not available in containers)
  targets.genericLinux.enable = false;
}
