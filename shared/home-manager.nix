{ inputs, self, username, homeDirectory, extraModules ? [ ]
, additionalUserProfiles ? { }, theme ? null, desktop, sharedModules ? [ ]
, monitors ? [ ], }:
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

    moduleUtils = import "${self}/shared/module-utils.nix" { inherit lib self; };
    baseModules = moduleUtils.importHomeFiles paths.modules;

    userProfiles = baseProfiles ++ additionalProfiles;

    validateProfile = profile:
      let profilePath = "${paths.homeProfiles}/${profile}.nix";
      in {
        inherit profile profilePath;
        error = if !builtins.pathExists profilePath then
          "Profile '${profile}' does not exist at ${toString profilePath}"
        else
          null;
      };

    validatedProfiles = map validateProfile userProfiles;

    invalidProfiles = lib.filter (p: p.error != null) validatedProfiles;

    validationErrors =
      lib.concatMapStringsSep "\n" (p: "  - ${p.error}") invalidProfiles;

    profilePaths =
      map (profile: "${paths.homeProfiles}/${profile}.nix") userProfiles;
  in {
    assertions = [{
      assertion = invalidProfiles == [ ];
      message = ''
        Home Manager profile validation failed for user '${username}':
        ${validationErrors}
      '';
    }];

    home-manager = {
      extraSpecialArgs = {
        inherit inputs self username homeDirectory theme desktop monitors;
        inherit (config.networking) hostName;
        inherit (config) myUsers;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${username} = {
        imports = extraModules ++ profilePaths ++ baseModules;
      };
      backupFileExtension = "backup";
      sharedModules = sharedModules;
    };
  })
