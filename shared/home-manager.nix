{ inputs, username, homeDirectory, extraModules ? [ ], theme ? null, desktop
}: [
  inputs.home-manager.nixosModules.home-manager
  ({ lib, config, pkgs, ... }: {
    home-manager = {
      extraSpecialArgs = {
        inherit inputs username homeDirectory theme desktop;
        inherit (config.networking) hostName;
        inherit (config) myUsers;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${username} = { imports = extraModules; };
      backupFileExtension = "backup";
    };
  })
]
