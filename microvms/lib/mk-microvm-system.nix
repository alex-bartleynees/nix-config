{ inputs }:
{ hostName, ipAddress, tapId, mac, gateway, extraVolumes ? [ ]
, extraShares ? [ ], extraModules ? [ ], username ? "alexbn"
, homeDirectory ? "/home/alexbn", additionalUserProfiles ? { }
, homeVolumeSize ? 40960, }:
let
  inherit (inputs) nixpkgs;
  self = inputs.self;
  lib = nixpkgs.lib;
  paths = import "${self}/paths.nix" self;
  moduleUtils = import "${paths.lib}/module-utils.nix" { inherit lib self; };
  hmModule = import "${paths.lib}/home-manager.nix" {
    inherit inputs self username homeDirectory additionalUserProfiles;
  };
  coreModules = moduleUtils.importAllNixFiles paths.modules;
  profileModules = moduleUtils.importAllNixFiles paths.profiles;
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  theme = import "${paths.themes}/tokyo-night.nix" { inherit inputs pkgs; };

  base = import "${paths.microvmsLib}/microvm-base.nix" {
    inherit hostName ipAddress tapId mac gateway;
    sshHostKeysDir =
      "/home/${username}/.config/microvm/${hostName}/ssh-host-keys";
    extraVolumes = [
      {
        image = "home.img";
        mountPoint = "/home/${username}";
        size = homeVolumeSize;
        fsType = "ext4";
        autoCreate = true;
      }
      {
        image = "nix-rw-store.img";
        mountPoint = "/nix/.rw-store";
        size = 20480;
        fsType = "ext4";
        autoCreate = true;
      }
    ] ++ extraVolumes;
    inherit extraShares;
  };
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs self;
    users = [{ inherit username homeDirectory; }];
  };
  modules = [
    inputs.microvm.nixosModules.microvm
    inputs.microvm.nixosModules.host
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix
    inputs.disko.nixosModules.disko
    inputs.nixos-wsl.nixosModules.wsl
    inputs.vscode-server.nixosModules.default
    "${paths.lib}/custom-options.nix"
    "${paths.lib}/locale.nix"
    "${paths.users}/${username}.nix"
    hmModule
    base
  ] ++ coreModules ++ profileModules ++ extraModules;
}
