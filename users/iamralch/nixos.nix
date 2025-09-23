{ pkgs, ... }:
{
  # user configuration
  users.users.iamralch = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    initialHashedPassword = "";
  };
}
