{ inputs }:
{ system ? "x86_64-linux", username, homeDirectory ? "/home/${username}"
, themeName ? "tokyo-night", userProfiles ? [ "developer" ], gitConfig ? { }
, extraModules ? [ ], }:
let
  inherit (inputs) nixpkgs home-manager;
  self = inputs.self;
  lib = nixpkgs.lib;
  paths = import "${self}/paths.nix" self;

  pkgs = import nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
    overlays = [ (import "${self}/overlays") ];
  };

  theme = import "${paths.themes}/${themeName}.nix" { inherit inputs pkgs; };

  moduleUtils = import "${paths.lib}/module-utils.nix" { inherit lib self; };
  homeModules = moduleUtils.importHomeFiles paths.modules;

in home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = {
    inherit inputs self username homeDirectory userProfiles;
    myUsers.${username} = { git = gitConfig; };
    osConfig = {
      myConfig = {
        inherit theme;
        desktop = "none";
        monitors = [ ];
        systemProfiles = [ ];
      };
    };
  };
  modules = homeModules ++ [{
    fonts.fontconfig.enable = true;
  }] ++ extraModules;
}
