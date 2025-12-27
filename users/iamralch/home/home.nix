{ lib, ... }:

let
  mkCopy = import ../../../modules/mkcopy.nix { inherit lib; };
in
{
  home = {
    stateVersion = "25.11";
    packages = [ ];

    activation = {
      claude = mkCopy "users/iamralch/.config/claude/settings.json" "$HOME/.claude/settings.json";
      gemini = mkCopy "users/iamralch/.config/gemini/settings.json" "$HOME/.gemini/settings.json";
    };
  };
}
