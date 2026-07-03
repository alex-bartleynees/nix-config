{ inputs, self, users, theme, desktop, hostName, additionalUserProfiles ? { }
, isDarwin ? true, }:
let
  paths = import "${self}/paths.nix" self;

  profileModules = [ "${paths.darwinProfiles}/${hostName}.nix" ];

  userModules = map (user: "${paths.users}/${user.username}.nix") users;

  baseImports = [
    ./custom-options.nix
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix
  ] ++ profileModules ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs self desktop additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
      sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
