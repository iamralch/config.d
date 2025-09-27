{ pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      shellInit = ''
        source ${pkgs.zinit}/share/zinit/zinit.zsh
      '';
    };
  };
}
