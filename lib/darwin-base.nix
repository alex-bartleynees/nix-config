{ inputs, self, users, theme, desktop, hostName, additionalUserProfiles ? { }
, isDarwin ? true, }:
let
  paths = import "${self}/paths.nix" self;

  darwinProfile = import "${paths.profiles}/${hostName}.nix";
  darwinModule =
    if builtins.isAttrs darwinProfile && darwinProfile ? darwinConfig then
      darwinProfile.darwinConfig
    else
      darwinProfile;
  darwinHomeModules =
    if builtins.isAttrs darwinProfile && darwinProfile ? homeConfig then
      [ darwinProfile.homeConfig ]
    else
      [ ];

  userModules = map (user: "${paths.users}/${user.username}.nix") users;

  baseImports = [
    ./custom-options.nix
    "${paths.profiles}/options.nix"
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix
    darwinModule
  ] ++ userModules;

  homeManagerImports = map (user:
    import ./home-manager.nix {
      inherit inputs self desktop additionalUserProfiles;
      username = user.username;
      homeDirectory = user.homeDirectory;
      sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
      extraModules = darwinHomeModules;
      inherit theme;
    }) users;

in {
  getImports = { additionalImports ? [ ], }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
