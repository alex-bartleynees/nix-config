{ inputs, username, homeDirectory, extraModules ? [ ], theme ? null, desktop }:
({ lib, config, pkgs, ... }:
  let
    userProfiles = if (config.myUsers ? ${username}
      && config.myUsers.${username} ? profiles) then
      config.myUsers.${username}.profiles
    else
      [ ];

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
    };
  })

