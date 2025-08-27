{ ... }: {
  services.tlp = {
    enable = true;
    settings = {
      # CPU Performance Settings
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT =
        0; # Disable turbo boost on battery for better efficiency
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0; # Disable dynamic boost on battery
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy Performance Policy (Intel P-state)
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power"; # More aggressive power saving

      # Platform Profile (ACPI)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power"; # More aggressive than "balanced"

      # CPU Frequency Scaling (additional fine-tuning)
      CPU_SCALING_MIN_FREQ_ON_AC = 400000; # 400 MHz minimum
      CPU_SCALING_MAX_FREQ_ON_AC = 4600000; # Allow full turbo on AC
      CPU_SCALING_MIN_FREQ_ON_BAT = 400000; # 400 MHz minimum
      CPU_SCALING_MAX_FREQ_ON_BAT =
        2600000; # Limit to base frequency on battery

      # Battery Care (your settings are good, minor adjustment)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80; # Slightly lower for better longevity

      # Disk Power Management
      DISK_DEVICES = "nvme0n1"; # T490 typically has NVMe SSD
      DISK_APM_LEVEL_ON_AC = "254 254"; # High performance
      DISK_APM_LEVEL_ON_BAT = "128 128"; # Balanced power saving
      DISK_IOSCHED = "mq-deadline mq-deadline"; # Good for SSDs

      # Graphics Power Management (Intel integrated)
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 200;
      INTEL_GPU_MAX_FREQ_ON_AC = 1150; # Full performance
      INTEL_GPU_MAX_FREQ_ON_BAT = 800; # Reduced for battery
      INTEL_GPU_BOOST_FREQ_ON_AC = 1150;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 600;

      # WiFi Power Management
      WIFI_PWR_ON_AC = "off"; # Full WiFi performance on AC
      WIFI_PWR_ON_BAT = "on"; # Enable WiFi power saving on battery

      # USB Power Management
      USB_AUTOSUSPEND = 1; # Enable USB autosuspend
      USB_DENYLIST = "8087:0aaa"; # Common Bluetooth device, adjust if needed

      # Audio Power Management
      SOUND_POWER_SAVE_ON_AC = 0; # No audio power saving on AC
      SOUND_POWER_SAVE_ON_BAT = 1; # Enable on battery

      # Runtime Power Management for PCI devices
      RUNTIME_PM_ON_AC = "auto"; # Can help even on AC for T490
      RUNTIME_PM_ON_BAT = "auto";

      # Radio Device Management
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth"; # Disable unused BT

      # Additional T490-specific optimizations
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave"; # Aggressive PCIe power saving

      # Network Interface Power Management
      WOL_DISABLE = "Y"; # Disable Wake-on-LAN to save power

      # Kernel laptop mode
      NMI_WATCHDOG = 0; # Disable NMI watchdog to save power
    };
  };
}
