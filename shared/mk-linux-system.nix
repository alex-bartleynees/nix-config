{ inputs }:
({ hostPath, system ? "x86_64-linux", desktop ? "hyprland", users
  , themeName ? "tokyo-night", hostName, enableThemeSpecialisations ? false
  , enableDesktopSpecialisations ? false, desktopSpecialisations ? [ ]
  , additionalModules ? [ ], additionalSpecialArgs ? { }
  , additionalUserProfiles ? { } }:
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
      inherit inputs users;
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

    # Desktop specialisations
    mkDesktopSpecialisations = import ./mk-desktop-specialisations.nix {
      inherit inputs;
      lib = nixpkgs.lib;
    };
    desktopSpecialisationModules = if enableDesktopSpecialisations then
      [
        (mkDesktopSpecialisations {
          baseImports = [ "${hostPath}/nixos/configuration.nix" ]
            ++ (if builtins.pathExists "${hostPath}/modules" then
              [ "${hostPath}/modules" ]
            else
              [ ]);
          inherit theme users;
          desktops = desktopSpecialisations;
        })
      ]
    else
      [ ];

    # Shared configuration
    shared = import ../shared/nixos-default.nix {
      inherit inputs theme desktop users additionalUserProfiles;
      lib = nixpkgs.lib;
    };

    # Host-specific modules
    hostModules = [ "${hostPath}/nixos/configuration.nix" ]
      ++ (if builtins.pathExists "${hostPath}/modules" then
        [ "${hostPath}/modules" ]
      else
        [ ]) ++ (if desktop != "none"
        && builtins.pathExists (../core/desktops + "/${desktop}.nix") then
          [ ../core/desktops/${desktop}.nix ]
        else
          [ ]);

  in nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit inputs users desktop hostName;
    } // additionalSpecialArgs;

    modules = shared.getImports {
      additionalImports = hostModules ++ additionalModules
        ++ [{ _module.args.theme = theme; }] ++ themeSpecialisations
        ++ desktopSpecialisationModules;
    };
  })

