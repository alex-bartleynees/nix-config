{ inputs }:
({ hostPath, system ? "x86_64-linux", desktop ? "hyprland", users
  , themeName ? "tokyo-night", hostName, enableThemeSpecialisations ? false
  , enableDesktopSpecialisations ? false, desktopSpecialisations ? [ ]
  , additionalModules ? [ ], additionalSpecialArgs ? { }
  , additionalUserProfiles ? { }, isDarwin ? false }:
  let
    inherit (inputs) nixpkgs nix-darwin;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Configuration path - use different paths for Darwin vs NixOS
    configPath =
      if isDarwin then "macos/configuration.nix" else "nixos/configuration.nix";

    # Theme setup - works for both Darwin and Linux
    theme = import ../core/themes/${themeName}.nix { inherit inputs pkgs; };
    themes = if !isDarwin then
      import ../core/themes {
        inherit inputs users;
        lib = nixpkgs.lib;
      }
    else
      null;
    themeSpecialisations = if enableThemeSpecialisations && !isDarwin then
      [
        (themes.mkThemeSpecialisations {
          baseImports = [ "${hostPath}/${configPath}" ]
            ++ (if builtins.pathExists "${hostPath}/modules" then
              [ "${hostPath}/modules" ]
            else
              [ ]);
          inherit desktop;
        })
      ]
    else
      [ ];

    # Desktop specialisations - only for non-Darwin systems
    mkDesktopSpecialisations = if !isDarwin then
      import ./mk-desktop-specialisations.nix {
        inherit inputs;
        lib = nixpkgs.lib;
      }
    else
      null;
    desktopSpecialisationModules =
      if enableDesktopSpecialisations && !isDarwin then
        [
          (mkDesktopSpecialisations {
            baseImports = [ "${hostPath}/${configPath}" ]
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

    # Shared configuration - works for both Darwin and NixOS
    shared = import ../shared/nixos-default.nix {
      inherit inputs theme desktop users additionalUserProfiles isDarwin;
      lib = nixpkgs.lib;
    };

    # Host-specific modules
    hostModules = [ "${hostPath}/${configPath}" ]
      ++ (if builtins.pathExists "${hostPath}/modules" then
        [ "${hostPath}/modules" ]
      else
        [ ]) ++ (if desktop != "none" && !isDarwin
        && builtins.pathExists (../core/desktops + "/${desktop}.nix") then
          [ ../core/desktops/${desktop}.nix ]
        else
          [ ]);

    # Base modules for the system
    baseModules = shared.getImports {
      additionalImports = hostModules ++ additionalModules
        ++ [{ _module.args.theme = theme; }] ++ themeSpecialisations
        ++ desktopSpecialisationModules;
    };

    # Common special args
    commonSpecialArgs = {
      inherit inputs users desktop hostName;
      self = inputs.self;
    } // additionalSpecialArgs;

  in if isDarwin then
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = baseModules;
    }
  else
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = baseModules;
    })

