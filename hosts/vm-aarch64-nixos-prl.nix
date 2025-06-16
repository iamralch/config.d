{ ... }: {
  # NixOS release from which default
  system.stateVersion = "25.05";

  # Hardware Config
  hardware.parallels.enable = true;

  # Network Config
  networking.hostName = "vm-aarch64-nixos-prl";
  networking.domain = "ralch.local";
}
