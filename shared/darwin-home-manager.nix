{ inputs, username, homeDirectory, theme ? "catppuccin-mocha"
, extraModules ? [ ] }:
let inherit (inputs) mac-app-util;
in [
  mac-app-util.darwinModules.default
  inputs.home-manager.darwinModules.home-manager

  ({ config, pkgs, ... }: {
    home-manager.extraSpecialArgs = {
      inherit inputs username homeDirectory theme;
      inherit (config.networking) hostName;
      background = import ../shared/background.nix { inherit inputs; };
    };
    home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    users.users.${username} = { home = homeDirectory; };
    home-manager.users.${username} = { imports = extraModules; };
    home-manager.backupFileExtension = "backup";
  })
]
