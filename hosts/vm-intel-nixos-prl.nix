{ ... }: {
  # NixOS release from which default
  system.stateVersion = "25.05";

  # Network Config
  networking.hostName = "vm-intel-nixos-prl";
  networking.domain = "ralch.local";
}
