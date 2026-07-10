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
    # mango's waybar modules (mango/workspaces, mango/window, ...) aren't in the
    # nixpkgs waybar release yet, so mangowc hosts build waybar from git instead.
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
      overlays = [ (import "${self}/overlays") ]
        ++ nixpkgs.lib.optionals (desktop == "mangowc")
        [ inputs.waybar.overlays.default ];
    };

    # Hardware configuration
    hardwareConfig = if builtins.pathExists
    "${paths.hardware}/${hostName}-hardware-configuration.nix" then
      [ "${paths.hardware}/${hostName}-hardware-configuration.nix" ]
    else
      [ ];

    # Disk configuration
    diskConfig = if builtins.pathExists
    "${paths.diskConfigs}/${hostName}-disk-config.nix" then
      [ "${paths.diskConfigs}/${hostName}-disk-config.nix" ]
    else
      [ ];

    baseImports = hardwareConfig ++ diskConfig;

    # Theme setup
    theme = import "${paths.themes}/${themeName}.nix" { inherit inputs pkgs; };
    hostConfig = {
      inherit theme desktop monitors hostName stateVersion systemProfiles;
    };

    themes = import paths.themes {
      inherit inputs self users additionalUserProfiles hostConfig;
      lib = nixpkgs.lib;
    };

    themeSpecialisations = if enableThemeSpecialisations then
      [ (themes.mkThemeSpecialisations { baseImports = baseImports; }) ]
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
          inherit users additionalUserProfiles hostConfig;
          desktops = desktopSpecialisations;
        })
      ]
    else
      [ ];

    # Shared configuration
    shared = import ./system-base.nix {
      inherit inputs self users additionalUserProfiles hostConfig;
      lib = nixpkgs.lib;
    };

    # Desktop module - extract nixosConfig from combined module if it exists
    moduleUtils = import ./module-utils.nix {
      inherit self;
      lib = nixpkgs.lib;
    };
    desktopConfig =
      if builtins.pathExists "${paths.desktops}/${desktop}.nix" then
        [ (moduleUtils.extractSystemConfig desktop) ]
      else
        [ ];

    # Base modules for the system
    baseModules = shared.getImports {
      additionalImports = baseImports ++ desktopConfig ++ additionalModules
        ++ themeSpecialisations ++ desktopSpecialisationModules;
    };

    # Common special args
    commonSpecialArgs = { inherit inputs self users; };

  in nixpkgs.lib.nixosSystem {
    inherit system pkgs;
    specialArgs = commonSpecialArgs;
    modules = baseModules;
  })
