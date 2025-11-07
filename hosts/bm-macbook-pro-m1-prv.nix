_: {
  # NixOS release from which default
  system.stateVersion = 6;

  # Network Config
  networking = {
    computerName = "Svetlin’s MacBook Pro M1";
    hostName = "macbook";
    domain = "ralch.local";
  };

  homebrew = {
    casks = [
      "discord"
      "plex-media-server"
    ];

    masApps = {
      "Kindle" = 302584613;
    };
  };
}
