{ inputs, username, homeDirectory, extraModules ? [ ]
, additionalUserProfiles ? { }, theme ? null, desktop, sharedModules ? [ ], }:
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

    importUtils = import ../shared/import-nix-files.nix { inherit lib; };
    baseModules = importUtils.importHomeFiles ../modules;

    userProfiles = baseProfiles ++ additionalProfiles;

    # Validate profiles exist and are home modules
    validateProfile = profile:
      let
        profilePath = ../profiles/${profile}.nix;
        profileExists = builtins.pathExists profilePath;
        profileContent =
          if profileExists then builtins.readFile profilePath else "";
        # Check if the file contains the homeModule marker in the first line
        isHomeModule = profileExists
          && (lib.hasPrefix "# homeModule: true" profileContent);
      in {
        inherit profile profilePath profileExists isHomeModule;
        error = if !profileExists then
          "Profile '${profile}' does not exist at ${toString profilePath}"
        else if !isHomeModule then
          "Profile '${profile}' is not a home module (missing '# homeModule: true' marker at ${
            toString profilePath
          })"
        else
          null;
      };

    validatedProfiles = map validateProfile userProfiles;

    invalidProfiles = lib.filter (p: p.error != null) validatedProfiles;

    validationErrors =
      lib.concatMapStringsSep "\n" (p: "  - ${p.error}") invalidProfiles;

    profilePaths = map (profile: ../profiles/${profile}.nix) userProfiles;
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
        inherit inputs username homeDirectory theme desktop;
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
