{ ... }: {
  imports = [
    ./boot.nix
    ./hardware.nix
    ./packages.nix
    ./services.nix
    ./virtualisation.nix
    ./stylix.nix
  ];
}

