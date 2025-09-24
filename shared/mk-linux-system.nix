{ inputs }:
{ hostPath, system ? "x86_64-linux", desktop ? "hyprland", username ? "alexbn"
, homeDirectory ? "/home/alexbn", themeName ? "tokyo-night"
, enableSpecialisations ? false, enableThemeSpecialisations ? false
, additionalModules ? [ ], additionalSpecialArgs ? { }, }:
let
  inherit (inputs) nixpkgs;

  # Constants
  allowUnfreeConfig = { allowUnfree = true; };

  # Package sets
  pkgs = import nixpkgs {
    inherit system;
    config = allowUnfreeConfig;
  };

  # Theme setup
  theme = import ../core/themes/${themeName}.nix { inherit inputs pkgs; };
  themes = import ../core/themes {
    inherit inputs;
    lib = nixpkgs.lib;
  };
  themeSpecialisations = if enableThemeSpecialisations then
    [
      (themes.mkThemeSpecialisations {
        baseImports = [ "${hostPath}/nixos/configuration.nix" ]
          ++ (if builtins.pathExists "${hostPath}/modules" then
            [ "${hostPath}/modules" ]
          else
            [ ]);
        inherit desktop;
      })
    ]
  else
    [ ];

  # Shared configuration
  shared = import ../shared/nixos-default.nix {
    inherit inputs theme desktop username homeDirectory;
  };

  # Host-specific modules
  baseHostModules = [ "${hostPath}/nixos/configuration.nix" ]
    ++ (if builtins.pathExists "${hostPath}/modules" then
      [ "${hostPath}/modules" ]
    else
      [ ]) ++ (if desktop != "none"
      && builtins.pathExists (../core/desktops + "/${desktop}.nix") then
        [ ../core/desktops/${desktop}.nix ]
      else
        [ ]);

  # Specialisation modules
  specialisationModules =
    if enableSpecialisations then [ "${hostPath}/specialisations" ] else [ ];

  # All host modules
  hostModules = baseHostModules ++ specialisationModules;

in nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs username homeDirectory desktop;
  } // additionalSpecialArgs;

  modules = shared.getImports {
    additionalImports = hostModules ++ additionalModules
      ++ [{ _module.args.theme = theme; }] ++ themeSpecialisations;
  };
}

