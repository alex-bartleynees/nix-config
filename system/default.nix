{ ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./hardware.nix
    ./locale.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./users.nix
    ./wayland.nix
    ./virtualisation.nix
    ./greeter.nix
  ];
}

