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
    ./greeter.nix
    ./stylix.nix
  ];
}

