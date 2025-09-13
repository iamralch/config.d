{ ... }: {
  # NixOS release from which default
  system.stateVersion = "25.05";

  # Network Config
  networking.hostName = "vm-docker-nixos-prv";
  networking.domain = "ralch.docker";

  # Boot Configuration
  boot.isContainer = true;
}
