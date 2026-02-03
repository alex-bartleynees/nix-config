{ lib, inputs, users, theme, desktop, hostName, additionalUserProfiles ? { }
, isDarwin ? true, }:
let
  # Core modules
  profileModules = [ ../profiles/darwin/${hostName}.nix ];

  # User modules
  userModules = map (user: ../users/${user.username}.nix) users;

  baseImports = [
    ./custom-options.nix
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix
  ] ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs desktop additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
      extraModules = [ ../modules/hm-home.nix ];
      sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
