_: {
  # nix configuration requires flakes
  nix = {
    settings.allowed-users = [ "*" ];
    settings.trusted-users = [ "@admin" ];
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # We use proprietary software on this machine
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
