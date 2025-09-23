{ pkgs, ... }:
{
  # Be careful updating this.
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";
  # configure the init ram-disk
  boot.initrd.kernelModules = [ ];
  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };
}
