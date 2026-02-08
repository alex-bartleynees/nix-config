{ inputs }:
({ system ? "x86_64-linux", stateVersion ? "25.05", systemProfiles
  , desktop ? "hyprland", users, themeName ? "tokyo-night", hostName
  , enableThemeSpecialisations ? false, enableDesktopSpecialisations ? false
  , desktopSpecialisations ? [ ], additionalModules ? [ ]
  , additionalSpecialArgs ? { }, additionalUserProfiles ? { }, }:
  let
    inherit (inputs) nixpkgs;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Hardware configuration
    hardwareConfig = if builtins.pathExists
    (../hardware + "/${hostName}-hardware-configuration.nix") then
      [ ../hardware/${hostName}-hardware-configuration.nix ]
    else
      [ ];

    # Disk configuration
    diskConfig = if builtins.pathExists
    (../hardware/disk-config + "/${hostName}-disk-config.nix") then
      [ ../hardware/disk-config/${hostName}-disk-config.nix ]
    else
      [ ];

    baseImports = hardwareConfig ++ diskConfig;

    # Theme setup
    theme = import ../themes/${themeName}.nix { inherit inputs pkgs; };
    themes = import ../themes {
      inherit inputs users additionalUserProfiles;
      lib = nixpkgs.lib;
    };

    themeSpecialisations = if enableThemeSpecialisations then
      [
        (themes.mkThemeSpecialisations {
          baseImports = baseImports;
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
          baseImports = baseImports;
          inherit theme users additionalUserProfiles;
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

    # Desktop module - extract nixosConfig from combined module if it exists
    extractors = import ../shared/module-extractors.nix;
    desktopConfig =
      if builtins.pathExists (../desktops + "/${desktop}.nix") then
        [ (extractors.extractSystemConfig desktop) ]
      else
        [ ];

    # Base modules for the system
    baseModules = shared.getImports {
      additionalImports = baseImports ++ desktopConfig ++ additionalModules
        ++ [{ _module.args.theme = theme; }] ++ themeSpecialisations
        ++ desktopSpecialisationModules;
    };

    # Common special args
    commonSpecialArgs = {
      inherit inputs users desktop hostName stateVersion systemProfiles;
      self = inputs.self;
    } // additionalSpecialArgs;

  in nixpkgs.lib.nixosSystem {
    inherit system pkgs;
    specialArgs = commonSpecialArgs;
    modules = baseModules;
  })
