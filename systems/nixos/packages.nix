{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kitty
    brave
    devpod
    ghostty
    zed-editor
    firefox-devedition
  ];
}
