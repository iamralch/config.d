{ lib, ... }:

let
  mkSymlink = import ../../../modules/mksymlink.nix { inherit lib; };
in
{
  imports = [ ./home.nix ];

  home.activation = {
    zshrc = mkSymlink "users/iamralch/.zshrc" "$HOME/.zshrc";
    config = mkSymlink "users/iamralch/.config" "$HOME/.config";
  };
}
