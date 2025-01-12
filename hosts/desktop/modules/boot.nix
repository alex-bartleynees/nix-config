# Bootloader

{ config, pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot = {
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    blacklistedKernelModules = [ "nouveau" ];
  };
}

