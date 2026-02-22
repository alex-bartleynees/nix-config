{ config, lib, ... }:
let cfg = config.nvidia;
in {
  options.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";

    prime = {
      enable = lib.mkEnableOption
        "NVIDIA PRIME (for hybrid graphics with integrated GPU)";

      mode = lib.mkOption {
        type = lib.types.enum [ "offload" "sync" ];
        default = "offload";
        description = ''
          PRIME mode: "offload" for on-demand switching, "sync" for always-on NVIDIA with better performance.
          Use "sync" for desktop workstations, "offload" for laptops to save power.
        '';
      };

      amdgpuBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:17:0:0";
        description =
          "Bus ID for AMD integrated GPU (use 'lspci | grep VGA' to find)";
      };

      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:0:2:0";
        description =
          "Bus ID for Intel integrated GPU (use 'lspci | grep VGA' to find)";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:1:0:0";
        description = "Bus ID for NVIDIA GPU (use 'lspci | grep VGA' to find)";
      };
    };
  };

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
        powerManagement.finegrained =
          cfg.prime.enable; # Only use finegrained with PRIME
        open = true;
        nvidiaSettings = true;
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
      virtualisation.docker.daemon.settings.features.cdi = true;
      hardware.nvidia-container-toolkit.enable = true;

      environment.sessionVariables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
      };
    })

    # NVIDIA PRIME configuration for hybrid graphics
    (lib.mkIf (cfg.enable && cfg.prime.enable) {
      hardware.nvidia.prime = lib.mkMerge [
        # Common PRIME settings
        {
          nvidiaBusId =
            lib.mkIf (cfg.prime.nvidiaBusId != "") cfg.prime.nvidiaBusId;
        }

        # AMD integrated GPU configuration
        (lib.mkIf (cfg.prime.amdgpuBusId != "") {
          amdgpuBusId = cfg.prime.amdgpuBusId;
        })

        # Intel integrated GPU configuration
        (lib.mkIf (cfg.prime.intelBusId != "") {
          intelBusId = cfg.prime.intelBusId;
        })

        # PRIME mode: offload (on-demand) or sync (always-on)
        (lib.mkIf (cfg.prime.mode == "offload") {
          offload = {
            enable = true;
            enableOffloadCmd = true; # Provides nvidia-offload command
          };
        })

        (lib.mkIf (cfg.prime.mode == "sync") { sync.enable = true; })
      ];
    })
  ];
}
