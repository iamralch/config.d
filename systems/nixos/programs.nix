{ pkgs, ... }: {
  programs.dconf.enable = true;
  programs.zsh.initExtra = ''
    source ${pkgs.zinit}/share/zinit/zinit.zsh
  '';
}
