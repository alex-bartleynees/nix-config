{ inputs, username, homeDirectory, extraModules ? [ ] }:
let
  inherit (inputs) mac-app-util;
  theme = import ../core/themes/tokyo-night.nix {
    inherit inputs;
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  };
in [
  mac-app-util.darwinModules.default
  inputs.home-manager.darwinModules.home-manager
  inputs.stylix.darwinModules.stylix

  ({ config, pkgs, ... }:
    let
      profiles = config.myUsers.${username}.profiles or [ ];
      profilePaths = map (profile: ../home/profiles/${profile}.nix) profiles;
    in {
      home-manager.extraSpecialArgs = {
        inherit inputs username homeDirectory theme;
        inherit (config.networking) hostName;
        inherit (config) myUsers;
        desktop = "macbook";
      };
      home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      users.users.${username} = { home = homeDirectory; };
      home-manager.users.${username} = {
        imports = extraModules ++ profilePaths;
      };
      home-manager.backupFileExtension = "backup";
    })
]
