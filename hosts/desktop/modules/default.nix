{ ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./hardware.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./wayland.nix
    ./virtualisation.nix
    ./regreet.nix
    ./stylix.nix
    ./sway.nix
  ];
}

