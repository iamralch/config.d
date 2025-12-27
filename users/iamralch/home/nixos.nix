{ ... }:

{
  imports = [ ./home.nix ];

  xdg.enable = true;

  home.file = {
    ".zshrc".source = ../.zshrc;
    ".config".source = ../.config;
  };
}
