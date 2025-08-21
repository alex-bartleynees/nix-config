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
  ];
}

