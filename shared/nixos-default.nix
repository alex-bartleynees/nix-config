{ lib, inputs, self, users, theme, desktop, additionalUserProfiles ? { }
, monitors ? [ ], }:
let
  paths = import "${self}/paths.nix" self;
  moduleUtils = import "${self}/shared/module-utils.nix" { inherit lib self; };
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
  ] ++ coreModules ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs self desktop additionalUserProfiles monitors;
      username = user.username;
      homeDirectory = user.homeDirectory;
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
