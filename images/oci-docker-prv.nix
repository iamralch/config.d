_: {
  # NixOS release
  system.stateVersion = "25.11";

  # Network Config
  networking = {
    hostName = "docker";
    domain = "ralch.local";
  };
}
