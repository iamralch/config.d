{ ... }: {
  # NixOS release from which default
  system.stateVersion = 6;

  # Network Config
  networking.hostName = "vm-aarch64-macos-prl";
  networking.domain = "ralch.local";
}
