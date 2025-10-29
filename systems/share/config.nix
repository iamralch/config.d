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
}
