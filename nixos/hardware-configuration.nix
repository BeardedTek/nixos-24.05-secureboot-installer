{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/profiles/all-hardware.nix")
      (modulesPath + "/profiles/installation-device.nix")
    ];
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "sata_nv"
    "ext4"
    "btrfs"
    "nvme"
    "ata_piix"
    "sata_uli"
    "sata_via"
    "sata_sis"
    "sd_mod"
    "sr_mod"
    "uhci_hcd"
    "ehci_hcd"
    "nouveau"
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ROOT_UUID";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BOOT_UUID";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
