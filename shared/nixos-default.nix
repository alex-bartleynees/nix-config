{ lib, inputs, users, theme, desktop, additionalUserProfiles ? { }
, isDarwin ? false, }:
let
  # Core modules
  importUtils = import ../shared/import-nix-files.nix { inherit lib; };
  coreModules =
    if isDarwin then [ ] else importUtils.importAllNixFiles ../modules;
  profileModules = if isDarwin then
    [ ../machines/macbook.nix ]
  else
    importUtils.importAllNixFiles ../profiles;

  # User modules
  userModules = map (user: ../users/${user.username}.nix) users;

  baseImports = [ ./custom-options.nix ] ++ (if isDarwin then [
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix
  ] else [
    ./locale.nix
    inputs.determinate.nixosModules.default
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-wsl.nixosModules.wsl
  ]) ++ coreModules ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs desktop additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
      extraModules = [ ../modules/hm-home.nix ];
      sharedModules = lib.optionals (isDarwin)
        [ inputs.mac-app-util.homeManagerModules.default ];
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
