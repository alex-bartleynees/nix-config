{ config, pkgs, theme, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Networking
  networking.hostName = "thinkpad";

  # Create host identifier file for impermanence auto-rebuild
  environment.etc."hostname-for-rebuild".text = "thinkpad";

  tailscale = {
    enable = true; # Enable Tailscale support
  };

  docker = {
    enable = true; # Enable Docker support
  };

  stylixTheming = {
    enable = true;
    image = theme.wallpaper;
  };

  sambaClient = { enable = true; };

  silentBoot.enable = false;

  zswap.enable = true;

  snapshots.enable = true;

  # Enable impermanence with BTRFS reset on boot
  impermanence = {
    enable = false;
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
    persistPaths = [
      # System critical paths
      "/etc/sops"
      "/etc/ssh" # SSH host keys
      "/etc/machine-id" # Unique machine identifier
      "/etc/hostname-for-rebuild" # Host identifier for auto-rebuild
      "/var/log" # System logs
      "/var/lib/nixos" # NixOS state
      "/var/lib/systemd/random-seed" # Random seed for reproducibility
      "/var/lib/systemd/coredump" # Core dumps for debugging
      "/var/lib/systemd/timers" # Systemd timer state
      "/var/lib/tailscale" # Tailscale state
      "/var/lib/bluetooth" # Bluetooth pairings and device info
      "/var/lib/colord" # Color management profiles
      "/var/lib/docker" # Docker images, containers, volumes, networks
      "/etc/NetworkManager/system-connections" # Wifi passwords and network configs

      # User authentication files (for testing - reduces security benefits)
      "/etc/shadow" # User password hashes
      "/etc/passwd" # User account info
      "/etc/group" # Group definitions
      "/etc/gshadow" # Group password hashes

      # User SSH and GPG keys
      "/home/alexbn/.ssh"
      "/home/alexbn/.gnupg"

      # Development tools
      "/home/alexbn/.config/JetBrains" # Rider settings and projects
      "/home/alexbn/.local/share/JetBrains" # Rider data
      "/home/alexbn/.dotnet" # .NET user secrets and tools
      "/home/alexbn/.nuget" # NuGet package cache

      # Browsers (profiles, bookmarks, extensions, passwords)
      "/home/alexbn/.config/BraveSoftware" # Brave browser data
      "/home/alexbn/.mozilla" # Firefox profiles and data

      # Applications with important user data
      "/home/alexbn/.local/share/obsidian" # Obsidian vaults and settings
      "/home/alexbn/Documents" # User documents
      "/home/alexbn/workspaces"

      # Config files
      "/home/alexbn/.config/nix-config"
      "/home/alexbn/.config/nix-devenv"
      "/home/alexbn/.config/nixos-secrets"
      "/home/alexbn/.config/dotfiles"
      "/home/alexbn/.config/sops"

      # Shell and terminal tools
      "/home/alexbn/.zsh_history"
      "/home/alexbn/.bash_history"
      "/home/alexbn/.p10k.zsh" # Powerlevel10k configuration
      "/home/alexbn/.local/share/atuin" # Atuin shell history database
      "/home/alexbn/.local/share/zoxide" # Zoxide frecency database
      "/home/alexbn/.config/tmuxinator" # Tmuxinator project configs
      "/home/alexbn/.local/share/nvim" # Neovim plugins and data
      "/home/alexbn/.cache/nvim" # Neovim cache
    ];
    resetSubvolumes = [ ]; # Reset all subvolumes except @snapshots
  };

  # Lid close
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Power button
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  # Power Management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.thermald.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [ brightnessctl powertop ];

  system.stateVersion = "25.05";
}
