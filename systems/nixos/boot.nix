{ pkgs, ... }:
{
  # Be careful updating this.
  boot = {
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "0";
      };
      efi.canTouchEfiVariables = true;
    };
    # configure the init ram-disk
    initrd = {
      kernelModules = [ ];
      availableKernelModules = [
        "ehci_pci"
        "xhci_pci"
        "usbhid"
        "sr_mod"
      ];
    };
  };

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
