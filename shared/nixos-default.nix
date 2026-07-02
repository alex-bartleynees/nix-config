{ lib, inputs, users, theme, desktop, additionalUserProfiles ? { }
, monitors ? [ ], }:
let
  # Core modules
  moduleUtils = import ../shared/module-utils.nix { inherit lib; };
  coreModules = moduleUtils.importAllNixFiles ../modules;
  profileModules = moduleUtils.importAllNixFiles ../profiles;

  # User modules
  userModules = map (user: ../users/${user.username}.nix) users;

  baseImports = [
    ./custom-options.nix
    ./locale.nix
    inputs.determinate.nixosModules.default
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-wsl.nixosModules.wsl
  ] ++ coreModules ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs desktop additionalUserProfiles monitors;
      username = user.username;
      homeDirectory = user.homeDirectory;
inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
