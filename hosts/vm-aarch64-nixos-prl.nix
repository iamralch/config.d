{ ... }: {
  # NixOS release from which default
  system.stateVersion = "25.05";

  # Network Config
  networking.hostName = "vm-aarch64-nixos-prl";
  networking.domain = "ralch.local";
}
