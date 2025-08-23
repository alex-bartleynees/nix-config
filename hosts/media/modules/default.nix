{ config, pkgs, ... }: {
  imports = [ ./cage.nix ./disk-config.nix ./storage.nix ./samba-host.nix ];
}
