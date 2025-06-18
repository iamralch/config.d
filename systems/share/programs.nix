{ pkgs, ... }: {
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    source ${pkgs.zinit}/share/zinit/zinit.zsh
  '';
}
