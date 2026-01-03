{ pkgs, ... }:
{
  system.primaryUser = "iamralch";
  # user configuration
  users.users.iamralch = {
    home = "/Users/iamralch";
    shell = pkgs.zsh;
  };

  launchd.user.agents.atuin-daemon = {
    command = "${pkgs.atuin}/bin/atuin daemon";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/Users/iamralch/Library/Logs/atuin-daemon.log";
      StandardErrorPath = "/Users/iamralch/Library/Logs/atuin-daemon-error.log";
    };
  };
}
