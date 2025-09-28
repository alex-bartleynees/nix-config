{ lib, inputs, users, theme, desktop }:
let
  # Core modules
  importUtils = import ../shared/import-nix-files.nix { inherit lib; };
  coreModules = importUtils.importAllNixFiles ../core/modules;
  profileModules = importUtils.importAllNixFiles ../core/profiles;

  # User modules
  userModules = map (user: ../users/${user.username}.nix) users;

  baseImports = [
    ./locale.nix
    ./custom-options.nix
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ] ++ coreModules ++ profileModules ++ userModules;

  homeManagerImports = lib.flatten (map (user:
    import ./home-manager.nix {
      inherit inputs desktop;
      username = user.username;
      homeDirectory = user.homeDirectory;
      extraModules = [ ../home ];
      inherit theme;
    }) users);

in {
  getImports = { additionalImports ? [ ] }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
