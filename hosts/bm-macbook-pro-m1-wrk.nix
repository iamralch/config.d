{ ... }:
{
  # NixOS release from which default
  system.stateVersion = 6;

  # Network Config
  networking.computerName = "Svetlin’s MacBook Pro M1";
  networking.hostName = "svetlin";
  networking.domain = "hippo.local";
}
