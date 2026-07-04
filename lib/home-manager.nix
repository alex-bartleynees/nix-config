{ inputs, self, username, homeDirectory, extraModules ? [ ]
, additionalUserProfiles ? { }, desktop, sharedModules ? [ ], monitors ? [ ], }:
({ lib, config, pkgs, ... }:
  let
    paths = import "${self}/paths.nix" self;

    baseProfiles = if (config.myUsers ? ${username}
      && config.myUsers.${username} ? profiles) then
      config.myUsers.${username}.profiles
    else
      [ ];

    additionalProfiles = if additionalUserProfiles ? ${username} then
      additionalUserProfiles.${username}.profiles or [ ]
    else
      [ ];

    moduleUtils = import ./module-utils.nix { inherit lib self; };
    baseModules = moduleUtils.importHomeFiles paths.modules;
    profileModules = moduleUtils.importHomeFiles paths.profiles;

    userProfiles = baseProfiles ++ additionalProfiles;
  in {
    home-manager = {
      extraSpecialArgs = {
        inherit inputs self username homeDirectory desktop monitors
          userProfiles;
        inherit (config) myUsers;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${username} = {
        imports = extraModules ++ baseModules ++ profileModules;
      };
      backupFileExtension = "backup";
      sharedModules = [ "${paths.lib}/custom-options.nix" ] ++ sharedModules;
    };
  })
