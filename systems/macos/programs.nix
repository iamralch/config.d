{ pkgs, ... }: {
  programs.zsh.shellInit = ''
    source ${pkgs.zinit}/share/zinit/zinit.zsh
  '';
}
