{ lib, ... }:

let
  mkCopy = import ../../packages/mkcopy.nix { inherit lib; };
  mkSymlink = import ../../packages/mksymlink.nix { inherit lib; };
in
{
  # Support
  xdg.enable = true;

  home = {
    # Home Manager
    stateVersion = "25.11";
    # User Packages
    packages = [ ];

    activation = {
      # Symlink directories (bypasses Nix store)
      zshrc = mkSymlink "users/iamralch/.zshrc" "$HOME/.zshrc";
      config = mkSymlink "users/iamralch/.config" "$HOME/.config";
      # Copy files (activate the settings)
      claude = mkCopy "users/iamralch/.config/claude/settings.json" "$HOME/.claude/settings.json";
      gemini = mkCopy "users/iamralch/.config/gemini/settings.json" "$HOME/.gemini/settings.json";
    };
  };
}
