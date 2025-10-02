{ config, lib, ... }:
let
  cfg = config.tlpSettings;
in {
  options.tlpSettings = {
    enable = lib.mkEnableOption "TLP power management with optimized settings";

    profile = lib.mkOption {
      type = lib.types.enum [ "laptop" "thinkpad" "custom" ];
      default = "laptop";
      description = "TLP profile to use";
    };

    battery = {
      startChargeThreshold = lib.mkOption {
        type = lib.types.int;
        default = 75;
        description = "Battery charge start threshold (%)";
      };

      stopChargeThreshold = lib.mkOption {
        type = lib.types.int;
        default = 80;
        description = "Battery charge stop threshold (%)";
      };
    };

    cpu = {
      scalingGovernorOnAC = lib.mkOption {
        type = lib.types.str;
        default = "performance";
        description = "CPU scaling governor when on AC power";
      };

      scalingGovernorOnBat = lib.mkOption {
        type = lib.types.str;
        default = "powersave";
        description = "CPU scaling governor when on battery";
      };

      boostOnAC = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CPU boost when on AC power";
      };

      boostOnBat = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CPU boost when on battery";
      };

      maxFreqOnBat = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Maximum CPU frequency on battery (Hz)";
      };
    };

    graphics = {
      enableIntelGpuSettings = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Intel GPU power management settings";
      };

      intelGpuMaxFreqOnBat = lib.mkOption {
        type = lib.types.int;
        default = 800;
        description = "Intel GPU maximum frequency on battery (MHz)";
      };
    };

    disk = {
      devices = lib.mkOption {
        type = lib.types.str;
        default = "nvme0n1";
        description = "Disk devices to manage";
      };

      ioScheduler = lib.mkOption {
        type = lib.types.str;
        default = "mq-deadline mq-deadline";
        description = "IO scheduler for disks";
      };
    };

    wifi = {
      powerSaveOnBat = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WiFi power saving on battery";
      };
    };

    usb = {
      autosuspend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable USB autosuspend";
      };

      denylist = lib.mkOption {
        type = lib.types.str;
        default = "8087:0aaa";
        description = "USB devices to exclude from autosuspend";
      };
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.oneOf [ lib.types.str lib.types.int lib.types.bool ]);
      default = {};
      description = "Additional TLP settings";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = lib.mkMerge [
        # Base settings for all profiles
        {
          # CPU Performance Settings
          CPU_BOOST_ON_AC = if cfg.cpu.boostOnAC then 1 else 0;
          CPU_BOOST_ON_BAT = if cfg.cpu.boostOnBat then 1 else 0;
          CPU_SCALING_GOVERNOR_ON_AC = cfg.cpu.scalingGovernorOnAC;
          CPU_SCALING_GOVERNOR_ON_BAT = cfg.cpu.scalingGovernorOnBat;

          # Battery Care
          START_CHARGE_THRESH_BAT0 = cfg.battery.startChargeThreshold;
          STOP_CHARGE_THRESH_BAT0 = cfg.battery.stopChargeThreshold;

          # Disk Power Management
          DISK_DEVICES = cfg.disk.devices;
          DISK_IOSCHED = cfg.disk.ioScheduler;

          # WiFi Power Management
          WIFI_PWR_ON_AC = if cfg.wifi.powerSaveOnBat then "off" else "on";
          WIFI_PWR_ON_BAT = if cfg.wifi.powerSaveOnBat then "on" else "off";

          # USB Power Management
          USB_AUTOSUSPEND = if cfg.usb.autosuspend then 1 else 0;
          USB_DENYLIST = cfg.usb.denylist;
        }

        # Laptop profile settings
        (lib.mkIf (cfg.profile == "laptop") {
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";
          DISK_APM_LEVEL_ON_AC = "254 254";
          DISK_APM_LEVEL_ON_BAT = "128 128";
          SOUND_POWER_SAVE_ON_AC = 0;
          SOUND_POWER_SAVE_ON_BAT = 1;
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";
        })

        # ThinkPad specific settings
        (lib.mkIf (cfg.profile == "thinkpad") {
          # CPU settings optimized for ThinkPad
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_BAT = 1;
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          # CPU Frequency Scaling
          CPU_SCALING_MIN_FREQ_ON_AC = 400000;
          CPU_SCALING_MAX_FREQ_ON_AC = 4600000;
          CPU_SCALING_MIN_FREQ_ON_BAT = 400000;
          CPU_SCALING_MAX_FREQ_ON_BAT = lib.mkIf (cfg.cpu.maxFreqOnBat != null) cfg.cpu.maxFreqOnBat;

          # Disk settings
          DISK_APM_LEVEL_ON_AC = "254 254";
          DISK_APM_LEVEL_ON_BAT = "128 128";

          # Audio Power Management
          SOUND_POWER_SAVE_ON_AC = 0;
          SOUND_POWER_SAVE_ON_BAT = 1;

          # Runtime Power Management
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";

          # Radio Device Management
          DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";

          # ThinkPad specific optimizations
          PCIE_ASPM_ON_AC = "default";
          PCIE_ASPM_ON_BAT = "powersupersave";

          # Network settings
          WOL_DISABLE = "Y";

          # Kernel settings
          NMI_WATCHDOG = 0;
        })

        # Intel GPU settings
        (lib.mkIf cfg.graphics.enableIntelGpuSettings {
          INTEL_GPU_MIN_FREQ_ON_AC = 300;
          INTEL_GPU_MIN_FREQ_ON_BAT = 200;
          INTEL_GPU_MAX_FREQ_ON_AC = 1150;
          INTEL_GPU_MAX_FREQ_ON_BAT = cfg.graphics.intelGpuMaxFreqOnBat;
          INTEL_GPU_BOOST_FREQ_ON_AC = 1150;
          INTEL_GPU_BOOST_FREQ_ON_BAT = 600;
        })

        # Custom settings override
        cfg.extraSettings
      ];
    };
  };
}