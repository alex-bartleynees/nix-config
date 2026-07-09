{ lib, inputs, self, users, additionalUserProfiles ? { }, hostConfig }:
let
  inherit (hostConfig)
    theme desktop monitors hostName stateVersion systemProfiles;

  paths = import "${self}/paths.nix" self;
  moduleUtils = import ./module-utils.nix { inherit lib self; };
  coreModules = moduleUtils.importAllNixFiles paths.modules;
  profileModules = moduleUtils.importAllNixFiles paths.profiles;

  userModules = map (user: "${paths.users}/${user.username}.nix") users;

  baseImports = [
    ./custom-options.nix
    ./locale.nix
    inputs.determinate.nixosModules.default
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-wsl.nixosModules.wsl
    inputs.microvm.nixosModules.host
    {
      myConfig = { inherit theme desktop monitors systemProfiles; };
      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    }
  ] ++ coreModules ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs self additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
