{ ... }: {
  rootPersistPaths = [
    # System critical paths
    "/etc/sops"
    "/etc/ssh" # SSH host keys
    "/etc/machine-id" # Unique machine identifier
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
  ];
}
