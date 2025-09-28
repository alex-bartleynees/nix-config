{ lib, inputs, username, homeDirectory, theme, desktop }:
let
  # Core modules
  importUtils = import ../shared/import-nix-files.nix { inherit lib; };
  coreModules = importUtils.importAllNixFiles ../core/modules;
  profileModules = importUtils.importAllNixFiles ../core/profiles;

  baseImports = [
    ./locale.nix
    ./custom-options.nix
    ../users/${username}.nix
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ] ++ coreModules ++ profileModules;

  homeManagerImports = import ./home-manager.nix {
    inherit inputs username homeDirectory desktop;
    extraModules = [ ../home ];
    inherit theme;
  };

in {
  getImports = { additionalImports ? [ ] }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
