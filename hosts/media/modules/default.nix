{ config, pkgs, ... }: {
  imports = [
    ./backup.nix
    ./cage.nix
    ./disk-config.nix
    ./samba-host.nix
    ./storage.nix
  ];
}
