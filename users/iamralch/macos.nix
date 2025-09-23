{ pkgs, ... }:
{
  system.primaryUser = "iamralch";
  # user configuration
  users.users.iamralch = {
    home = "/Users/iamralch";
    shell = pkgs.zsh;
  };
}
