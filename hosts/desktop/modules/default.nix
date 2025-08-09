{ ... }: {
  imports = [
    ./packages.nix
    ./services.nix
    ./virtualisation.nix
    ./stylix.nix
    ./samba.nix
  ];
}

