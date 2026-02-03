{ lib, inputs, users, theme, desktop, additionalUserProfiles ? { }, }:
let
  # Core modules
  importUtils = import ../shared/import-nix-files.nix { inherit lib; };
  coreModules = importUtils.importAllNixFiles ../modules;
  profileModules = importUtils.importAllNixFiles ../profiles;

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
      inherit inputs desktop additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
      extraModules = [ ../modules/hm-home.nix ];
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
