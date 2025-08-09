{ config, lib, pkgs, ... }:
let cfg = config.nvidia;
in {
  options.nvidia = { enable = lib.mkEnableOption "NVIDIA GPU support"; };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot = {
        kernelParams = [
          "nvidia-drm.modeset=1"
          "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
          #"nvidia_drm.fbdev=1"
        ];
        kernelModules = [ "nvidia_uvm" ];
        blacklistedKernelModules = [ "nouveau" ];
      };

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = true;
        open = true;
        nvidiaSettings = true;
        prime = {
          offload.enable = true;
          amdgpuBusId = "PCI:17:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #   version = "570.86.16"; # use new 570 drivers
      #   sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
      #   openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
      #   settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
      #   usePersistenced = false;
      # };

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.sessionVariables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
      };
    })
  ];
}
