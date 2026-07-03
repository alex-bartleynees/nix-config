{ inputs }:
({ system ? "x86_64-linux", stateVersion ? "25.05", systemProfiles
  , desktop ? "hyprland", users, themeName ? "tokyo-night", hostName
  , enableThemeSpecialisations ? false, enableDesktopSpecialisations ? false
  , desktopSpecialisations ? [ ], additionalModules ? [ ]
  , additionalUserProfiles ? { }, monitors ? [ ], }:
  let
    inherit (inputs) nixpkgs;
    self = inputs.self;
    paths = import "${self}/paths.nix" self;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Hardware configuration
    hardwareConfig =
      if builtins.pathExists "${paths.hardware}/${hostName}-hardware-configuration.nix" then
        [ "${paths.hardware}/${hostName}-hardware-configuration.nix" ]
      else
        [ ];

    # Disk configuration
    diskConfig =
      if builtins.pathExists "${paths.diskConfigs}/${hostName}-disk-config.nix" then
        [ "${paths.diskConfigs}/${hostName}-disk-config.nix" ]
      else
        [ ];

    baseImports = hardwareConfig ++ diskConfig;

    # Theme setup
    theme = import "${paths.themes}/${themeName}.nix" { inherit inputs pkgs; };
    themes = import paths.themes {
      inherit inputs self users additionalUserProfiles monitors;
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
      inherit inputs self;
      lib = nixpkgs.lib;
    };

    desktopSpecialisationModules = if enableDesktopSpecialisations then
      [
        (mkDesktopSpecialisations {
          baseImports = baseImports;
          inherit theme users additionalUserProfiles monitors;
          desktops = desktopSpecialisations;
        })
      ]
    else
      [ ];

    # Shared configuration
    shared = import ./nixos-default.nix {
      inherit inputs self theme desktop users additionalUserProfiles monitors;
      lib = nixpkgs.lib;
    };

    # Desktop module - extract nixosConfig from combined module if it exists
    moduleUtils = import ./module-utils.nix { inherit self; lib = nixpkgs.lib; };
    desktopConfig =
      if builtins.pathExists "${paths.desktops}/${desktop}.nix" then
        [ (moduleUtils.extractSystemConfig desktop) ]
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
      inherit inputs self users desktop hostName stateVersion systemProfiles
        monitors;
    };

  in nixpkgs.lib.nixosSystem {
    inherit system pkgs;
    specialArgs = commonSpecialArgs;
    modules = baseModules;
  })
