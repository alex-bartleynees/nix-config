{ inputs, username, homeDirectory, extraModules ? [ ]
, additionalUserProfiles ? { }, theme ? null, desktop, sharedModules ? [ ] }:
({ lib, config, pkgs, ... }:
  let
    baseProfiles = if (config.myUsers ? ${username}
      && config.myUsers.${username} ? profiles) then
      config.myUsers.${username}.profiles
    else
      [ ];

    additionalProfiles = if additionalUserProfiles ? ${username} then
      additionalUserProfiles.${username}.profiles or [ ]
    else
      [ ];

    userProfiles = baseProfiles ++ additionalProfiles;

    profilePaths = map (profile: ../home/profiles/${profile}.nix) userProfiles;
  in {
    home-manager = {
      extraSpecialArgs = {
        inherit inputs username homeDirectory theme desktop;
        inherit (config.networking) hostName;
        inherit (config) myUsers;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${username} = { imports = extraModules ++ profilePaths; };
      backupFileExtension = "backup";
      sharedModules = sharedModules;
    };
  })

