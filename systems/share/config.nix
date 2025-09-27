_: {
  # nix configuration requires flakes
  nix = {
    settings = {
      allowed-users = [ "*" ];
      trusted-users = [ "@admin" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # We use proprietary software on this machine
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
    };
  };
}
