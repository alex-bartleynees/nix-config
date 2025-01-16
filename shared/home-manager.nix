{ inputs, username, homeDirectory, extraModules ? [ ], theme ? null }: [
  inputs.home-manager.nixosModules.home-manager

  ({ lib, config, pkgs, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
      })
    ];

    home-manager = {
      extraSpecialArgs = {
        inherit inputs username homeDirectory theme;
        inherit (config.networking) hostName;
        background = import ../shared/background.nix { inherit inputs; };
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${username} = { imports = extraModules; };
      backupFileExtension = "backup";
    };
  })
]
