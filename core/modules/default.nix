{ ... }: {
  imports = [
    ./gaming.nix
    ./nvidia.nix
    ./openrgb.nix
    ./system-packages.nix
    ./tailscale.nix
    ./docker.nix
    ./stylix.nix
    ./virtualisation.nix
    ./system.nix
    ./display-manager.nix
    ./secrets.nix
    ./zswap.nix
    ./silent-boot.nix
    ./samba-client.nix
    ./snapshots.nix
  ];
}

