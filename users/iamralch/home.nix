{ ... }:

{ config, ... }: 
let
  pwd = "${config.home.homeDirectory}/Projects/github.com/iamralch/config.d/users/iamralch";
in {
  # Support
  xdg.enable = true;

  # Home Manager
  home.stateVersion = "25.05";

  # User Packages
  home.packages = [];

  # User Configuration
  home.file = {
    ".config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${pwd}/.config";
      recursive = true;
    };

    ".zshrc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${pwd}/.zshrc";
      recursive = true;
    };
  };
}
